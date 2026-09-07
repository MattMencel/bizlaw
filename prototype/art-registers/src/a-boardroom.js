// ---------------------------------------------------------------- A · Boardroom
// The register to beat. Faces and staging carry the beat; the Offer sits in a thin
// dock and the Terms Board is a panel that covers the room when you open it.
let boardOpen = false;

const avA = (who, state) => window.ART.avataaars[who][state];

function trackA(t) {
  const silent0 = t.ours === null && t.theirs === null;
  const marks = silent0 ? "" : laidOut([
    { cls: "thrs", v: t.theirs, who: "Arrowmark, Day 2", label: t.theirLabel },
    { cls: "ours", v: t.ours, who: "you", label: t.ourLabel },
    { cls: "asp", v: t.asp, who: "Dana asked for", label: t.aspLabel },
  ].filter(m => !silent0)).map(m => `<span class="mk ${m.cls}" style="left:${Math.min(88, Math.max(12, m.v))}%;top:${2 + m.row * 30}px">
      <b>${m.who}</b>${m.label}</span>`).join("");
  const silent = t.ours === null && t.theirs === null;
  return `<div class="track">
    <div class="hd"><span class="k">${t.k}</span>
      <span class="v">${silent ? "not on the table" : ""}</span></div>
    <div class="line">${marks}</div>
    ${silent ? `<div class="silent">${t.asp === null ? "Neither Side has raised it." : `Dana asked for ${t.aspLabel.toLowerCase()}. Nobody has put it on the table.`}</div>` : ""}
  </div>`;
}

function renderA() {
  const b = bandOf(), q = quote(), spent = BEAT.exchange.spentBefore;
  const pips = Array.from({ length: BEAT.exchange.budget }, (_, i) =>
    `<span class="pip ${i < spent + q ? "quoted" : "free"}"></span>`).join("");

  const rides = BEAT.exhibits.map(e => {
    const on = !!S.riding[e.id], dud = on && !relevant(e);
    return `<button class="ride ${on ? "on" : ""} ${dud ? "dud" : ""}" data-ex="${e.id}">
      ${e.name}${on ? `<span class="tag">${dud ? "no bearing · still spent · still served" : "rides"}</span>` : ""}
    </button>`;
  }).join("");

  const rows = docketRows();
  const rail = `<div class="rail"><h4>Docket · Day ${BEAT.day}</h4>
    ${rows.length ? rows.map(r => `<div class="row">${r.what}
      <div class="m">Day ${r.day} · ${r.who}${r.cost ? ` · ${r.cost} pt` : ""} · ${r.lands}</div>
    </div>`).join("") : `<div class="empty">${BEAT.docketEmptyCopy}</div>`}</div>`;

  const board = boardOpen
    ? `<div class="board"><h4>Terms Board</h4>
        ${BEAT.terms.map(trackA).join("")}
        <button class="ride" data-act="board" style="margin-top:10px">Close</button></div>`
    : "";

  return `<div class="reg-a">
    <div class="wall"></div>
    <div class="seats">
      <div class="seat left"><div class="av">${avA("eleanor", "fixed")}</div>
        <div class="who"><b>${BEAT.cast.eleanor.name}</b>${BEAT.cast.eleanor.role}</div></div>
      <div class="seat right"><div class="av">${avA("marcus", "fixed")}</div>
        <div class="who"><b>${BEAT.cast.marcus.name}</b>${BEAT.cast.marcus.role}</div></div>
    </div>
    <div class="table"></div>
    <div class="props"></div>
    <div class="mine">${avA("dana", S.band)}
      <div class="say"><span class="band">${b.word}</span>
        “${b.line}”
        <span class="src">Dana Whitfield · from your Consult this morning</span></div>
    </div>
    <div class="hud">
      <div class="top">
        <span class="sim">${BEAT.sim}</span>
        <span class="day">Day ${BEAT.day} of ${BEAT.days} · ${BEAT.team} · ${BEAT.side}</span>
        <button class="boardtab" data-act="board">${boardOpen ? "Hide" : "Terms Board"}</button>
        <span class="pips"><span class="half">Exchange</span>${pips}</span>
      </div>
      ${board}
      ${boardOpen ? "" : rail}
      <div class="dock">
        <h4>Your staged Offer</h4>
        <div class="offer">${money(BEAT.offer.money)}, a written apology, an unqualified neutral reference
          <em>— staged by ${BEAT.offer.by}, ${BEAT.offer.staged}</em></div>
        <div class="rides">${rides}</div>
        <div class="commit">
          <button disabled>Commit Offer</button>
          <span class="why">${seconderList()} can second this. You staged it.</span>
          <span class="price">${q} of ${BEAT.exchange.budget} exchange points — Offer ${1}${riding().length ? ` + ${riding().length} Exhibit${riding().length > 1 ? "s" : ""}` : ""}</span>
        </div>
      </div>
    </div>
  </div>`;
}
