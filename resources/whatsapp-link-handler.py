#!/usr/bin/env python3

import sys
import subprocess
from urllib.parse import urlsplit, parse_qs


WHATSAPP_EXEC = "/usr/bin/webbridge-desktop"

# Browser di fallback per i collegamenti non WhatsApp.
BROWSER = "/usr/bin/firefox"



def whatsapp_url(value):
    try:
        url = urlsplit(value)
        phone = None
        recognized = False

        if url.scheme == "https":

            if url.hostname in ("wa.me", "www.wa.me"):
                if url.username or url.password or url.port:
                    return None

                parts = [p for p in url.path.split("/") if p]
                if len(parts) > 1:
                    return None

                phone = parts[0] if parts else None
                recognized = True

            elif (
                url.hostname in (
                    "api.whatsapp.com",
                    "www.whatsapp.com",
                    "web.whatsapp.com"
                )
                and url.path == "/send"
            ):
                if url.username or url.password or url.port:
                    return None

                phone = parse_qs(url.query).get("phone", [None])[0]
                recognized = True

        elif (
            url.scheme == "whatsapp"
            and url.hostname == "send"
            and url.path in ("", "/")
        ):
            phone = parse_qs(url.query).get("phone", [None])[0]
            recognized = True

        if not recognized:
            return None

        message = parse_qs(
            url.query, keep_blank_values=True
        ).get("text", [None])[0]

        if phone:
            phone = phone.lstrip("+")

            if not (
                phone.isascii()
                and phone.isdecimal()
                and 5 <= len(phone) <= 15
            ):
                return None

        if message is not None and len(message) > 16000:
            return None

        if not phone and not message:
            return None

        from urllib.parse import urlencode

        params = {}

        if phone:
            params["phone"] = phone

        if message:
            params["text"] = message

        return (
            "https://web.whatsapp.com/send?"
            + urlencode(params)
        )

    except (ValueError, TypeError):
        return None


def main():
    if len(sys.argv) < 2:
        return 1

    original = sys.argv[1]
    target = whatsapp_url(original)

    if target:
        subprocess.Popen(
            [WHATSAPP_EXEC, target],
            start_new_session=True
        )
        return 0

    # Evita di inoltrare protocolli non autorizzati.
    try:
        parsed = urlsplit(original)
    except ValueError:
        return 1

    if parsed.scheme not in ("https", "http"):
        return 1

    subprocess.Popen(
        [BROWSER, original],
        start_new_session=True
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
