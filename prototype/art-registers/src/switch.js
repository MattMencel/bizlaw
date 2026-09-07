// ---------------------------------------------------------------- switcher (chrome)
// Not part of any design under judgement. ?register=A|B|C, ?chrome=off for screenshots.
const REGISTERS = [["A", "The Boardroom"], ["B", "The Console"], ["C", "The Paper"]];
const RENDER = { A: renderA, B: renderB, C: renderC };

const params = new URLSearchParams(location.search);
let reg = (params.get("register") || "A").toUpperCase();
if (!RENDER[reg]) reg = "A";
if (params.get("chrome") === "off") document.documentElement.classList.add("chrome-off");
if (params.get("band") === "ready") S.band = "ready";
if (params.get("docket") === "empty") S.docketEmpty = true;

function go(r) {
  reg = r;
  // A data: or file: snapshot refuses replaceState; the switcher still has to work.
  try {
    const u = new URL(location.href); u.searchParams.set("register", r);
    history.replaceState(null, "", u);
  } catch (_) {}
  render();
}
const cycle = d => go(REGISTERS[(REGISTERS.findIndex(([k]) => k === reg) + d + 3) % 3][0]);

function render() {
  const [k, name] = REGISTERS.find(([x]) => x === reg);
  document.getElementById("stage").innerHTML = RENDER[k]();
  document.getElementById("now").textContent = `${k} — ${name}`;
  for (const el of document.querySelectorAll("#bar [data-probe]"))
    el.classList.toggle("on", el.dataset.probe === (el.dataset.group === "band" ? S.band
      : el.dataset.group === "docket" ? (S.docketEmpty ? "empty" : "day4") : ""));
  const d = document.getElementById("dump");
  d.textContent = JSON.stringify({
    register: k, band: S.band, docket: S.docketEmpty ? "empty" : "day 4",
    riding: riding().map(e => e.name),
    irrelevantRiding: riding().filter(e => !relevant(e)).map(e => e.name),
    quote: quote(), exchangeLeft: left(),
  }, null, 2);
}

document.addEventListener("click", e => {
  const ex = e.target.closest("[data-ex]");
  if (ex) { S.riding[ex.dataset.ex] = !S.riding[ex.dataset.ex]; return render(); }
  const act = e.target.closest("[data-act]");
  if (act && act.dataset.act === "board") { boardOpen = !boardOpen; return render(); }
  const p = e.target.closest("[data-probe]");
  if (!p) return;
  if (p.dataset.group === "band") S.band = p.dataset.probe;
  if (p.dataset.group === "docket") S.docketEmpty = p.dataset.probe === "empty";
  if (p.dataset.group === "reg") go(p.dataset.probe);
  render();
});
addEventListener("keydown", e => {
  if (/^(INPUT|TEXTAREA)$/.test(e.target.tagName) || e.target.isContentEditable) return;
  if (e.key === "ArrowLeft") cycle(-1);
  if (e.key === "ArrowRight") cycle(1);
});

document.body.insertAdjacentHTML("beforeend", `
  <pre id="dump" hidden></pre>
  <div id="bar">
    <button onclick="cycle(-1)">←</button>
    <span class="now" id="now"></span>
    <button onclick="cycle(1)">→</button>
    <span class="sep"></span>
    <span class="lab">Band</span>
    <button data-probe="firm" data-group="band">firm</button>
    <button data-probe="ready" data-group="band">ready</button>
    <span class="lab">Docket</span>
    <button data-probe="day4" data-group="docket">Day 4</button>
    <button data-probe="empty" data-group="docket">empty</button>
    <span class="sep"></span>
    <button onclick="const d=document.getElementById('dump');d.hidden=!d.hidden">state</button>
  </div>`);
render();
