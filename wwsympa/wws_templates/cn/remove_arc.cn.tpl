<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>操作成功</b>。
邮件将尽快被删除。这个任务可能在几分钟内完成，不要忘记重新载入涉及到的页面。
[ELSIF status = no_msgid]
<b>无法找到要删除的邮件，也许收到此邮件时没有“Message-Id:”。请用完整的 URL
或涉及到的邮件向邮递表管理者询问。</b>
[ELSIF status = not_found]
<b>无法找到要删除的邮件</b>
[ELSE]
<b>在删除此邮件时发生错误，请用完整的 URL 或涉及到的邮件向邮递表管理者询问。</b>
[ENDIF]
