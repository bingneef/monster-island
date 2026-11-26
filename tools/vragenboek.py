"""Maak het afdrukbare vragenboek opnieuw met python3 tools/vragenboek.py."""
from pathlib import Path
from html import escape
import json
import base64

root = Path(__file__).resolve().parents[1]
bank = json.loads((root / "game/data/vragen.json").read_text())
pages = ['''<!doctype html><html lang="nl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Het vragenboek van Monstereiland</title><style>
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#faf5e7;color:#204548;font:17px/1.55 system-ui,sans-serif}header,main{max-width:990px;margin:auto;padding:2rem}header{padding-top:3rem}h1,h2,h3{line-height:1.15}h1{font: bold clamp(38px,7vw,70px)/1.02 Georgia,serif;margin:.2em 0}h2{font: bold 35px Georgia,serif;margin:.3em 0}h3{font-size:21px}nav a{display:inline-block;color:#205653;padding:.35em .8em;margin:.2em;border:1px solid #9eb6a3;border-radius:20px;text-decoration:none}article{margin:0 0 3rem;border-top:5px solid #ecbc65;padding-top:1.3rem}img.portrait{width:76px;height:76px;object-fit:contain;float:right;margin:0 1rem}section{padding:0 0 1rem}table{width:100%;border-collapse:collapse}td,th{text-align:left;border-bottom:1px solid #cad6c9;padding:.45em;vertical-align:top}th{background:#e4ecdb}small{color:#4e665c}summary{cursor:pointer;color:#13615e;font-weight:650}.flag{display:inline-block;vertical-align:middle;width:66px;height:42px;box-shadow:0 0 0 1px #829589;margin:.4em .5em .4em 0}.tile{display:inline-block;white-space:nowrap;margin-right:1rem}.sum{font-variant-numeric:tabular-nums;display:inline-block;margin:.18em .65em .18em 0}.all{max-height:300px;overflow:auto}.samples{background:#e8efde;padding:.65em 1em;border-radius:8px}footer{padding:1rem}button{font:inherit;color:#fff;background:#296463;padding:.4em .9em;border:none;border-radius:12px}@media print{body{background:white;font-size:10pt}header,main{padding:0}nav,button,details{display:none}article{break-before:page;margin:0}tr,h3,.tile{break-inside:avoid}h3{break-after:avoid}.flag,th{print-color-adjust:exact;-webkit-print-color-adjust:exact}}</style>
<header><h1>Het vragenboek van Monstereiland</h1><p>Elke bewoner heeft een eigen niveau. Een gewone bewoner wordt je vriend na drie goede antwoorden. Een glinsterende bewoner vraagt er vijf. Een fout antwoord mag je opnieuw proberen.</p>
<p>Hier vind je de vragen, vlaggen en juiste antwoorden uit het spel. Bij rekenen kun je elke mogelijke som bekijken. Het spel schudt de antwoorden bij elke ontmoeting.</p>
<button onclick="window.print()">Druk het vragenboek af</button><nav>''']
pages.extend(f'<a href="#{k}">{k}</a>' for k in bank)
pages.append('</nav></header><main>')
for monster, entry in bank.items():
    portrait = (root / "game" / "creatures" / "portraits" / (monster+".png")).read_bytes()
    image = base64.b64encode(portrait).decode("ascii")
    pages.append(f'<article id="{monster}"><img class="portrait" src="data:image/png;base64,{image}" alt=""><h2>{monster}</h2><p>{entry["thema"]}</p>')
    for level, name in enumerate(entry["namen"]):
        count = 5 if level == 3 else 3
        pages.append(f'<section><h3>Niveau {level+1} · {name}{" ★" if level == 3 else ""}</h3><small>{count} goede antwoorden</small>')
        if "vragen" in entry:
            pages.append('<table><tr><th>Vraag</th><th>Goed antwoord</th><th>Andere keuzes</th></tr>')
            for q, good, *other in entry["vragen"][level]:
                pages.append(f'<tr><td>{escape(q)}</td><td><b>{escape(good)}</b></td><td>{escape(" · ".join(other))}</td></tr>')
            pages.append('</table>')
        elif "vlaggen" in entry:
            pages.append('<p>Van welk land is deze vlag? Twee andere landen uit dit rijtje staan als keuzes naast het juiste land.</p>')
            start, end = entry["groepen"][level]
            for country, kind, *colors in entry["vlaggen"][start:end]:
                if kind == 'dot':
                    fill = f'radial-gradient(circle at center,#{colors[1]} 0 12px,#{colors[0]} 12.5px)'
                else:
                    stops = ','.join(f'#{c} {100*i/len(colors):.4f}% {100*(i+1)/len(colors):.4f}%' for i,c in enumerate(colors))
                    fill = f'linear-gradient({"90deg" if kind=="v" else "180deg"},{stops})'
                pages.append(f'<span class="tile"><i class="flag" style="background:{fill}"></i>{country}</span>')
        else:
            top_a, top_b = entry["grenzen"][level]
            multiply = monster == 'CycloVolt'
            low = 2 if multiply else 1
            forward, back = ('×','÷') if multiply else ('+','−')
            def pair(a,b):
                result = a*b if multiply else a+b
                return f'{a} {forward} {b} = {result}', f'{result} {back} {b} = {a}'
            examples = [*pair(low,low),*pair(top_a,top_b)]
            pages.append(f'<p>Het spel kiest het eerste getal van {low} tot {top_a} en het tweede van {low} tot {top_b}. De twee bewerkingen wisselen elkaar af. {"Elke deelsom komt uit op een heel getal." if multiply else "Bij aftrekken blijft het antwoord positief."}</p>')
            pages.append('<p class="samples">'+' &nbsp; · &nbsp; '.join(examples)+'</p><details><summary>Bekijk alle mogelijke sommen met antwoorden</summary><div class="all">')
            for a in range(low,top_a+1):
                pages.append('<p>'+''.join(f'<span class="sum">{x}</span>' for b in range(low,top_b+1) for x in pair(a,b))+'</p>')
            pages.append('</div></details>')
        pages.append('</section>')
    pages.append('</article>')
pages.append('</main></html>')
(root / "Vragenboek.html").write_text('\n'.join(pages))
