./diceware -p -W 10 \
| echo -e "*$(cat -)*"'\n\nYour New Password!\nCopy somewhere safe!!\n\nthis message will self destruct in 30 seconds...' \
| keybase chat send gooseus \
| sleep 30;echo -e '{"method": "read", "params": {"options": {"channel": {"name": "gooseus,gooseus"}, "pagination": {"num": 1}}}}' \
| keybase chat api \
| grep -o '"msg":{"id":\(\d\+\)' \
| grep -o '\d\+' \
| echo '{"method": "delete", "params": {"options": {"channel": {"name": "gooseus,gooseus"}, "message_id":'"$(cat -)}}}" \
| keybase chat api