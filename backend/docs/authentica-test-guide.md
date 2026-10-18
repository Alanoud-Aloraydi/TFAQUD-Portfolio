# Authentica test guide (TFQD-12)

Goal: create the Authentica application and key, test `send-otp` and
`verify-otp` with the free OTPs, and record the answers that the public
documentation does not give. The answers go into section 8 of
`docs/api-contracts.md`.

The script `scripts/authentica_probe.py` makes the calls and keeps a log. It was
checked against a fake local server only. The real answers must come from you,
because only you have the key and the phone.

## 1. Rules for the key

- The key lives in an environment variable and in your real `.env` file, which
  git ignores. It is never committed.
- Never paste the key in a chat, a ticket, a screenshot or a commit.
- The script never prints the key and never writes it to the log.
- If the key appears anywhere by mistake, create a new key in the portal and
  delete the old one.
- Use your own phone number. Each test SMS goes to a real phone.

## 2. What the documentation already says

| Item | Documented |
|---|---|
| Base URL | `https://api.authentica.sa/api/v2` |
| Key | Header `X-Authorization: <key>` |
| Send | `POST /send-otp`. Body: `method` (`sms`, `whatsapp` or `email`), `phone` (international format, `+` and digits), `template_id` (default `1`). |
| Verify | `POST /verify-otp`. Body: `phone` and `otp`. |
| Success answers | Send: `{"success": true, "data": null, "message": "OTP send successfully"}`. Verify: `{"status": true, "message": "OTP verified successfully"}`. |
| Error answer | Only the 401 for a wrong or missing key: `{"errors": [{"message": "Unauthorized"}]}`. |
| Balance | `GET /balance` answers `{"success": true, "data": {"balance": <credits>}, ...}`. |

What is not documented, and what these tests find out:

- The answer for a wrong code, an expired code, a bad phone number, or too many
  requests.
- How long a code stays valid.
- Whether our own code is used when the `otp` field is sent. The workflow guide
  shows an `otp` field on send, but the API reference for `send-otp` does not
  list it.
- Which sender name the user sees, and how to change it. The `send-otp` reference
  has no `sender_name` field. The documentation says that your own sender name
  is registered with Authentica, and that the default OTP options are set in the
  Application settings of the dashboard. Test 11 sends a `sender_name` field to
  see what happens.
- Which values of `template_id` exist. The reference gives only the default
  `1` and the examples `1` and `31`.

The sources also disagree on the verify answer: the reference says `status`, a
code comment in the vendor's GitHub examples says `verified`. Record what the
real answer contains.

## 3. Set up

1. Sign in at `portal.authentica.sa`, create an application, and copy its API
   key.
2. Put the key in the environment of your terminal window, without showing it.

   macOS or Linux (bash or zsh):

   ```
   printf "Authentica API key: "; read -s AUTHENTICA_API_KEY; echo; export AUTHENTICA_API_KEY
   ```

   Windows PowerShell (not run on Windows here):

   ```
   $env:AUTHENTICA_API_KEY = [System.Net.NetworkCredential]::new("", (Read-Host "Authentica API key" -AsSecureString)).Password
   ```

3. From the project folder, look at a call without sending anything. Use
   `python3` if your system has no `python`.

   ```
   python scripts/authentica_probe.py --dry-run send --phone +9665XXXXXXXX
   ```

4. Check that the key works. This sends no SMS and shows your credits:

   ```
   python scripts/authentica_probe.py balance
   ```

   Write down the number. You need it in test 2.

## 4. The tests

In every command, replace `+9665XXXXXXXX` with your number. Add
`--note "text"` to label a call in the log. Each `send` asks you to type `yes`.
Read the SMS on your phone after every `send`: the code, the language of the
message, the sender name, and how many seconds it took.

| # | Test | Commands | What to record |
|---|---|---|---|
| 1 | Wrong key | `--bad-key balance` | The answer format of a 401. |
| 2 | Normal send, and its cost | `balance`, then `send --phone +9665XXXXXXXX`, then `balance` again | The answer of `send`. Credits used by one SMS. On the phone: the sender name, the code length, the text. |
| 3 | Correct code | `verify --phone +9665XXXXXXXX --otp <code from the SMS>` | The answer of a successful verify. |
| 4 | Same code again | Repeat test 3 at once | Whether a used code still works. The answer if it does not. |
| 5 | Wrong code | `send`, then `verify ... --otp <wrong code>`, then `verify ... --otp <correct code>` | The answer for a wrong code. Whether the correct code still works after a wrong try. Use a wrong code of the same length as the real one (4 digits with the default template, 6 with template 5). |
| 6 | Bad phone number | `send --phone 05XXXXXXXX` (your own number, local format, no `+966`) | Whether the number is rejected, and the answer. Whether an SMS arrives anyway. Never use another person's number. |
| 7 | Our own code | `send --phone +9665XXXXXXXX --otp 123456`, read the SMS, then `verify ... --otp 123456` and, if the SMS code differs, `verify ... --otp <code from the SMS>` | Which code arrived on the phone, and which code verify accepts. |
| 8 | An expired code | `send --phone +9665XXXXXXXX --template-id 5`. Write down the time. Wait 5 minutes and 10 seconds, then `verify ... --otp <code from the SMS>` | The answer for an expired code. It must be refused: the dashboard setting is 300 seconds. Test 3 showed that a code was still valid after 4 minutes 12 seconds. |
| 9 | Sending twice quickly | `send ... --template-id 5 --yes`, then the same command again within 10 seconds. Read both SMS. Then `verify ... --otp <first code>` and `verify ... --otp <second code>` | Whether the second send is refused, and the answer. Whether the first code still works after the second send. |
| 10 | Template 5 | `send --phone +9665XXXXXXXX --template-id 5`, then `verify ... --otp <code from the SMS>`, then the same `verify` again | On the phone: the language, the code length, the sender name, and the name of the application in the text. The answer of the first verify and of the second (the code used a second time). |
| 11 | Sender name | `send --phone +9665XXXXXXXX --sender-name TFAQUD` | The answer: accepted, ignored or refused (4xx). |

Tests 1, 2, 3, 5 and 7 were run on 17 October 2026, test 11 on 18 October, and
test 10 on 19 October (results in section 8 of `docs/api-contracts.md`). Test 4
was done once, inside test 10. Authentica checks the code (section 7), so tests 8
and 9 are needed: they show what Authentica does with an expired code and with
two sends. The answer for a bad phone number (test 6) is recorded with the F01
tests.

## 5. Where the answers are

Every call is saved in `authentica_probe_log.jsonl` in the folder where you ran
the script. Each line has the time, the command, your note, the status, the
response headers worth keeping (rate-limit and retry headers), and the response
body. The phone number and the code are hidden in the log. Git ignores the file.

To read it as a list:

```
python -c "import json; [print(r['time_utc'], r['command'], r['note'], r['status'], r['response_body']) for r in map(json.loads, open('authentica_probe_log.jsonl'))]"
```

## 6. The four answers

Copy the result into section 8 of `docs/api-contracts.md`.

| Question | Where to find it |
|---|---|
| Response format of `send-otp` and `verify-otp`, including errors | The `response_body` of tests 1 to 11. Write one example for each: success, wrong code, expired code, used code, bad phone, bad key, too many requests. |
| How long a code stays valid | 300 seconds, set in the Authentica dashboard. Test 3 showed that a code was still valid after 4 minutes 12 seconds. Test 8 shows that it is refused after 300 seconds. |
| Whether Authentica sends our own code | Test 7: the code on the phone, and which codes verify accepted. |
| Which sender name the user sees | The SMS on the phone (tests 2 and 7). Note whether the name comes from Authentica or from your application settings. |

## 7. The decision

Decided on 19 October 2026: Authentica makes the code (`template_id` 5, 6 digits,
Arabic text), keeps it for 300 seconds (a setting in the Authentica dashboard) and
checks it with `verify-otp`. Our server counts the wrong tries (3) and the codes
per phone number per hour (3). The reasons and the OTP rules are in section 8 of
`docs/api-contracts.md`.

Left to do (each send costs one credit):

1. Test 8, the expired code. It shows that the 300 seconds are applied.
2. Test 9, sending twice quickly.
3. Write the exact answer of the second `verify` of test 10 (the code used a
   second time). It is in the log (section 5).
4. Read the name of the application in the SMS of template 5. It must read
   TFAQUD. If it does not, change the name of the application in the dashboard.
5. Register the sender name `TFAQUD` with Authentica (test 11 was refused).

## 8. After the tests

- Close the terminal window, or clear the variable: `unset AUTHENTICA_API_KEY`
  (PowerShell: `Remove-Item Env:AUTHENTICA_API_KEY`).
- Keep the log until the answers are in the contracts document, then delete it.
- Put the key only in the environment of the server (staging and production).

## 9. If something goes wrong

| What you see | Cause and fix |
|---|---|
| `The environment variable AUTHENTICA_API_KEY is not set` | Do step 3.2 in the same terminal window. |
| `HTTP 401` with your real key | The key is wrong or was copied with a space. Create a new key. |
| `No answer: ...` | No network, or the base URL is blocked. Check your connection. |
| `HTTP 4xx` on `send` | That is an answer to record. Read the body. |
| No SMS arrives | Record it, with the time. Try WhatsApp: add `--method whatsapp`. |

Sources: the Authentica documentation at `docs.authentica.sa` (the pages
Welcome, OTP Verification Workflow, Send OTP, Verify OTP, Get Current Balance)
and the vendor's GitHub examples at `github.com/AuthenticaSA/Authentica`.
