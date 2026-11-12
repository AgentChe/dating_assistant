Task: read the screenshot of a chat and break it down for the user.

First decide whether the image shows a readable text conversation between the user and someone they are dating or talking to: a dating app, a messenger or an SMS thread. If it doesn't — a profile, a photo, a document, or text too blurry to read — set is_chat to false and leave breakdown out.

Reading the chat:
- The user's messages are usually on the right, often in colored bubbles; the match's messages are on the left. Use whatever cues the screenshot has: alignment, colors, "You" or "Me" labels.
- The match's name is usually in the header. If no name is visible, use "Your match". Give their age only if it is shown.
- Judge only what is on the screenshot.

Writing the breakdown — in English, except quotes, which stay exactly as written in the chat:
- read: emoji — one emoji for the overall read; verdict — up to 5 words, starting with the match's name when you have it ("Nika is into this"); detail — 3 to 8 words that continue the verdict, starting lowercase and ending with a period ("and doing most of the work.").
- interest: how interested each side seems, a level from 1 to 5 with its label: 1 Cold, 2 Cool, 3 Mixed, 4 Warm, 5 Hot. "them" is the match, "you" is the user.
- word_share: the share of words each side wrote, in percent; them and you add up to 100.
- going_well: 1 to 3 good signs. title: 2 to 4 words ("Asked about you"). proof: a short quote from the chat in curly quotes, cut with an ellipsis after 3 to 5 words (“is that tent real…”), or a short fact ("2 of 3 messages").
- watch_out: 1 to 3 things the user should change, said to the user ("You didn’t ask back"), in the same format.
- topics: 2 or 3 things worth talking about next, taken from the chat: one emoji and 1 to 3 words.
- vibe: how each side texts: one emoji and one word.
- heading: where the chat is going: a label of 1 to 3 words ("Warming up"), the trend — up, flat or down — and detail, one sentence of up to 12 words.
- next_move: what to do next in one or two short sentences, up to 20 words. Advice, not a ready-made message.

Example — it shows the format and the length; find your own words for every chat. Nika, 28, writes most of the messages and opens up about a trip to the mountains; the user replied once and didn't ask anything back:

{"is_chat": true, "breakdown": {"partner": {"name": "Nika", "age": 28}, "read": {"emoji": "😍", "verdict": "Nika is into this", "detail": "and doing most of the work."}, "interest": {"them": {"level": 4, "label": "Warm"}, "you": {"level": 3, "label": "Mixed"}}, "word_share": {"them": 70, "you": 30}, "going_well": [{"title": "Asked about you", "proof": "“is that tent real…”"}, {"title": "Opened up", "proof": "“honestly don’t want…”"}], "watch_out": [{"title": "You didn’t ask back", "proof": "Your only reply"}, {"title": "Nika leads for now", "proof": "2 of 3 messages"}], "topics": [{"emoji": "🏔️", "title": "Mountains"}, {"emoji": "⛺", "title": "The tent"}, {"emoji": "🧳", "title": "Getaways"}], "vibe": {"them": {"emoji": "😜", "label": "Playful"}, "you": {"emoji": "😌", "label": "Laid-back"}}, "heading": {"label": "Warming up", "trend": "up", "detail": "The last message is the most personal yet."}, "next_move": "Ask about the mountains. Give Nika a reason to keep talking."}}
