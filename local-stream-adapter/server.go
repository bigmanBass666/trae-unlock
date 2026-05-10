package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

type SSEEvent struct {
	ID    string      `json:"id,omitempty"`
	Event string      `json:"event,omitempty"`
	Data  interface{} `json:"data"`
}

type AdapterRequest struct {
	Headers map[string]string `json:"headers,omitempty"`
	Body    string            `json:"body,omitempty"`
}

func sseAdapterHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req AdapterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	upstreamURL := osGetEnv("UPSTREAM_URL", "https://api.internal.com/v1/stream")

	client := NewChromeClient()

	upstreamReq, err := http.NewRequestWithContext(r.Context(), "POST", upstreamURL, strings.NewReader(req.Body))
	if err != nil {
		http.Error(w, fmt.Sprintf("create upstream request failed: %v", err), http.StatusInternalServerError)
		return
	}

	for k, v := range req.Headers {
		upstreamReq.Header.Set(k, v)
	}
	if upstreamReq.Header.Get("Accept") == "" {
		upstreamReq.Header.Set("Accept", "text/event-stream")
	}
	if upstreamReq.Header.Get("Cache-Control") == "" {
		upstreamReq.Header.Set("Cache-Control", "no-cache")
	}

	resp, err := client.Do(upstreamReq)
	if err != nil {
		http.Error(w, fmt.Sprintf("upstream request failed: %v", err), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		http.Error(w, fmt.Sprintf("upstream returned %d: %s", resp.StatusCode, string(body)), resp.StatusCode)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming not supported", http.StatusInternalServerError)
		return
	}

	scanner := bufio.NewScanner(resp.Body)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)

	eventID := 0
	var currentData strings.Builder
	currentEvent := "message"

	for scanner.Scan() {
		line := scanner.Text()

		if strings.HasPrefix(line, "event:") {
			currentEvent = strings.TrimSpace(strings.TrimPrefix(line, "event:"))
			continue
		}

		if strings.HasPrefix(line, "data:") {
			dataContent := strings.TrimSpace(strings.TrimPrefix(line, "data:"))
			if currentData.Len() > 0 {
				currentData.WriteString("\n")
			}
			currentData.WriteString(dataContent)
			continue
		}

		if line == "" && currentData.Len() > 0 {
			eventID++
			sseEvent := SSEEvent{
				ID:    fmt.Sprintf("%d", eventID),
				Event: currentEvent,
				Data:  parseDataField(currentData.String()),
			}

			jsonBytes, err := json.Marshal(sseEvent)
			if err != nil {
				log.Printf("marshal sse event failed: %v", err)
				currentData.Reset()
				currentEvent = "message"
				continue
			}

			fmt.Fprintf(w, "id: %d\nevent: %s\ndata: %s\n\n", eventID, sseEvent.Event, string(jsonBytes))
			flusher.Flush()

			currentData.Reset()
			currentEvent = "message"
			continue
		}

		if strings.HasPrefix(line, "id:") || strings.HasPrefix(line, "retry:") || strings.HasPrefix(line, ":") {
			continue
		}
	}

	if currentData.Len() > 0 {
		eventID++
		sseEvent := SSEEvent{
			ID:    fmt.Sprintf("%d", eventID),
			Event: currentEvent,
			Data:  parseDataField(currentData.String()),
		}
		jsonBytes, _ := json.Marshal(sseEvent)
		fmt.Fprintf(w, "id: %d\nevent: %s\ndata: %s\n\n", eventID, sseEvent.Event, string(jsonBytes))
		flusher.Flush()
	}

	if err := scanner.Err(); err != nil {
		log.Printf("scanner error: %v", err)
	}
}

func parseDataField(raw string) interface{} {
	var parsed interface{}
	if err := json.Unmarshal([]byte(raw), &parsed); err == nil {
		return parsed
	}
	return raw
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"ok","timestamp":"%s"}`, time.Now().Format(time.RFC3339))
}

func runModule3() {
	listenAddr := osGetEnv("LISTEN_ADDR", "127.0.0.1:8317")

	mux := http.NewServeMux()
	mux.HandleFunc("/v1/adapter", sseAdapterHandler)
	mux.HandleFunc("/health", healthHandler)

	server := &http.Server{
		Addr:         listenAddr,
		Handler:      mux,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 0,
		IdleTimeout:  120 * time.Second,
	}

	fmt.Printf("SSE adapter server listening on %s\n", listenAddr)
	fmt.Printf("  POST /v1/adapter - SSE protocol adapter\n")
	fmt.Printf("  GET  /health     - Health check\n")
	fmt.Printf("  Upstream: %s\n", osGetEnv("UPSTREAM_URL", "https://api.internal.com/v1/stream"))

	if err := server.ListenAndServe(); err != nil {
		fmt.Fprintf(os.Stderr, "server error: %v\n", err)
		os.Exit(1)
	}
}
