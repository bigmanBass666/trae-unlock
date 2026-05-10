async verifyCommand(e) {
                    if (!this.currentSession) return;
                    let {
                        planItemId: t,
                        agentMessageId: r,
                        userConfirmStatus: i
                    } = e;
                    try {
                        let n = await this._taskService.provideUserResponse({
                            task_id: e?.task_id,
                            type: e?.type,
                            toolcall_id: e?.toolcall_id,
                            tool_name: e?.tool_name,
                            decision: e?.decision,
                            confirm_config: e?.confirm_config,
                            params: e?.params
                        });
                        if (n?.code !== 0) return console.error("provideUserResponse error", n), {
                            isError: !0
                        };
                        let a = n?.data?.confirm_info;
                        if (!a) return;
                        if (i === xA.AutoRunConfigChange) {
                            let {
                                currentSession: e
                            } = this, i = e.messages.find(e => e.agentMessageId === r);
                            if (!i) return;
                            let n = i.agentTaskContent?.guideline?.planItems.find(e => e.planItemId === t);
                            if (!n) return;
                            return MU(n) && (console.log("verifyCommand", a), n.confirm_info = a), this._sessionStore.actions.setCurrentSession(e), {
                                confirm_info: a
                            }
                        }
                        if (i === xA.VerifyAndConfirm) return {
                            confirm_info: a
                        }
                    } catch (e) {
                        return console.error("provideUserResponse error", e), {
                            isError: !0
                        }
                    }
                }