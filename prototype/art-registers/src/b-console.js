// ---------------------------------------------------------------- B · Console
// No scene, so no commission and no faked table. Everything is a screen the firm's
// case system draws; the cast is pixel busts at 44px in a strip.
const avB = (who, state) => window.ART.pixel[who][state];

function trackB(t) {
  const silent0 = t.ours === null && t.theirs === null;
  const marks = silent0 ? "" : laidOut([
    { cls: "thrs", v: t.theirs, who: "them", label: t.theirLabel },
    { cls: "ours", v: t.ours, who: "you", label: t.ourLabel },
    { cls: "asp", v: t.asp, who: "Dana asked", label: t.aspLabel },
  ].filter(m => !silent0)).map(m => `<span class="mk ${m.cls}" style="left:${Math.min(88, Math.max(12, m.v))}%;bottom:${2 + m.row * 15}px">${m.who} ${m.label}</span>`).join("");
  const silent = t.ours === null && t.theirs === null;
  return `<div class="track">
    <span class="dim">${t.k.toUpperCase()}</span>
    <span class="rule"><span class="base"></span>${marks}
      ${silent ? `<span class="none" style="position:absolute;bottom:2px;left:0">${t.asp === null ? "not on the table" : `not on the table — Dana asked for ${t.aspLabel.toLowerCase()}`}</span>` : ""}
    </span>
  </div>`;
}

function renderB() {
  const b = bandOf(), q = quote();
  const pips = "▮".repeat(BEAT.exchange.spentBefore + q)
             + "▯".repeat(BEAT.exchange.budget - BEAT.exchange.spentBefore - q);

  const fig = (who, state, extra = "") => `<div class="fig">${avB(who, state)}
    <div class="n">${BEAT.cast[who].name}</div><div class="r">${BEAT.cast[who].role}</div>${extra}</div>`;

  const ex = BEAT.exhibits.map(e => {
    const on = !!S.riding[e.id], dud = on && !relevant(e);
    return `<button class="ex" data-ex="${e.id}"><span class="box3">[${on ? "x" : " "}]</span>
      ${e.name} <span class="dim">· bears on ${e.bears.join(", ")}</span>
      ${dud ? `<span class="note">· NO BEARING ON THIS OFFER — spent anyway, served anyway</span>` : ""}
    </button>`;
  }).join("");

  const rows = docketRows();
  return `<div class="reg-b">
    <div class="head">
      <span class="t hi">WHITFIELD v ARROWMARK LOGISTICS</span>
      <span class="dim">DAY ${String(BEAT.day).padStart(2, "0")}/${BEAT.days}</span>
      <span class="dim">${BEAT.team.toUpperCase()} · ${BEAT.side.toUpperCase()}</span>
      <span class="dim">TERMINAL ${BEAT.you.toUpperCase()}</span>
      <span style="margin-left:auto">EXCHANGE ${pips} <span class="dim">${q} quoted</span></span>
    </div>

    <div class="grid">
      <div class="box"><span class="cap">CLIENT</span>
        <div class="cast">
          ${fig("dana", S.band, `<div class="band">${b.word.toUpperCase()}</div>`)}
          <div class="consult">“${b.line}”
            <div class="dim" style="margin-top:6px">Dana Whitfield · Consult, this morning · 1 pt</div>
          </div>
        </div>
      </div>

      <div class="box"><span class="cap">ACROSS THE TABLE</span>
        <div class="cast">
          ${fig("marcus", "fixed")}
          ${fig("eleanor", "fixed")}
        </div>
        <div class="dim" style="margin-top:8px">Presence, not a read. Their faces are authored and never move.</div>
      </div>

      <div class="box wide"><span class="cap">STAGED OFFER</span>
        <div class="hi">${money(BEAT.offer.money)} · written apology · unqualified neutral reference</div>
        <div class="dim">staged by ${BEAT.offer.by} · ${BEAT.offer.staged} · not on the table until it commits</div>
        <div class="rows" style="margin-top:10px">${ex}</div>
        <div class="prompt">
          <span class="dim">${BEAT.you.toLowerCase().replace(" ", ".")}@kestrel:day4$</span>
          <button class="dead" disabled>commit offer</button>
          <span class="cursor"></span>
          <span class="warn">✗ second required — ${seconderList().toLowerCase()}. you staged it.</span>
          <span class="dim" style="margin-left:auto">price ${q}/${BEAT.exchange.budget}: offer 1${riding().length ? ` + ${riding().length} exhibit` : ""}</span>
        </div>
      </div>

      <div class="box"><span class="cap">TERMS</span>
        ${BEAT.terms.map(trackB).join("")}
      </div>

      <div class="box"><span class="cap">DOCKET</span>
        ${rows.length ? `<div class="log">${rows.map(r => `<div>
            <span class="dim">D${r.day}</span> ${r.what}
            <span class="dim">· ${r.who}${r.cost ? ` · ${r.cost}pt` : ""} · ${r.lands}</span></div>`).join("")}</div>`
          : `<div class="empty">${BEAT.docketEmptyCopy}</div>`}
      </div>
    </div>
  </div>`;
}
