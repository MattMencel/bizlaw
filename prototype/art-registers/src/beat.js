// The beat, shared by all three registers so the comparison is about register only.
// Day 4 of Whitfield v. Arrowmark Logistics. You are PRIYA NAIR, plaintiff Side,
// Team Kestrel. You have staged an Offer; the Exhibits ride the staged Offer (#291),
// and the commit control in your hand is dead because the Second is not yours to give.

const BEAT = {
  sim: "Whitfield v. Arrowmark Logistics",
  side: "Plaintiff", team: "Kestrel", you: "Priya Nair",
  day: 4, days: 10,
  exchange: { budget: 4, spentBefore: 0 },
  seconders: ["Tom Ellis", "Jordan Beck"],
  cast: {
    dana:    { name: "Dana Whitfield", role: "Your client", expressive: true },
    marcus:  { name: "Marcus Reyes",   role: "Opposing counsel" },
    eleanor: { name: "Eleanor Voss",   role: "Arrowmark Logistics · VP People" },
  },
  offer: {
    by: "Priya Nair", staged: "Day 4, 09:12",
    money: 185000,
    terms: ["Money", "Written apology", "Neutral reference"],
  },
  exhibits: [
    { id: "log",   name: "HR Complaint Log, 2023–24",     from: "Records request, Day 2",
      bears: ["Money", "Policy change"] },
    { id: "depo",  name: "Ex-Supervisor Deposition, p.41", from: "Deposition, landed Day 4",
      bears: ["Money", "Written apology"] },
    { id: "audit", name: "Warehouse Safety Audit, 2022",   from: "In the file at the open",
      bears: ["Training"] },
  ],
  // Their track is their LAST COMMITTED Offer read whole (Day 2). A Term it did not
  // mention is silent, not zero. The third marker is the Client's ASPIRATION, authored
  // sparsely — never Par, which no student sees before Release.
  terms: [
    { k: "Money",             ours: 62,   ourLabel: "$185,000",
      theirs: 21, theirLabel: "$60,000",  asp: 88,   aspLabel: "$250,000" },
    { k: "Written apology",   ours: 100,  ourLabel: "Signed, by the VP",
      theirs: 0,  theirLabel: "Refused",  asp: 100,  aspLabel: "Required" },
    { k: "Neutral reference", ours: 100,  ourLabel: "Unqualified",
      theirs: 85, theirLabel: "12 months", asp: null, aspLabel: null },
    { k: "NDA",               ours: 20,   ourLabel: "Narrow",
      theirs: 96, theirLabel: "Mutual, full", asp: null, aspLabel: null },
    { k: "Training",          ours: null, ourLabel: null,
      theirs: null, theirLabel: null,    asp: 70,   aspLabel: "Manager training" },
    { k: "Policy change",     ours: null, ourLabel: null,
      theirs: null, theirLabel: null,    asp: 80,   aspLabel: "Written policy" },
  ],
  docket: [
    { day: 3, who: "Jordan Beck", what: "Deposed ex-supervisor",   cost: 2, lands: "landed Day 4" },
    { day: 4, who: "Priya Nair",  what: "Consulted Dana Whitfield", cost: 1, lands: "landed Day 4" },
    { day: 4, who: "Priya Nair",  what: "Staged Offer — $185,000 + 2 terms", cost: 0, lands: "needs a Second" },
  ],
  docketEmptyCopy: "Nothing here yet. Every Action your Team spends lands on this page — who spent it, what it cost, and the Day the result arrives.",
  // Shown at a Consult and nowhere else. A Band that moves is never shown the moment
  // it moves, so this line is Day 4's Consult, not a live readout.
  band: {
    firm:  { word: "Firm",  line: "Sixty thousand and a gag order. I gave them a year of my life — I'm not signing that." },
    ready: { word: "Ready", line: "I'm tired, Priya. If the apology is real and it's in writing, I could live with the rest." },
  },
};

let S = {
  band: "firm",
  docketEmpty: false,
  riding: { log: true, depo: true, audit: true },
};

const money = n => "$" + n.toLocaleString("en-US");
const riding = () => BEAT.exhibits.filter(e => S.riding[e.id]);
// One price for the whole play: the Offer plus exhibit_price for each Exhibit riding.
const quote = () => 1 + riding().length;
const left = () => BEAT.exchange.budget - BEAT.exchange.spentBefore - quote();
// An Exhibit is relevant where the Offer touches a Term it bears on. An irrelevant one
// is still spent and still served — it just moves nothing.
const relevant = e => e.bears.some(t => BEAT.offer.terms.includes(t));
const docketRows = () => (S.docketEmpty ? [] : BEAT.docket);
const bandOf = () => BEAT.band[S.band];
const seconderList = () => BEAT.seconders.join(" or ");

// Two markers within 22% of each other collide, so alternate their rows.
function laidOut(marks) {
  const live = marks.filter(m => m.v !== null).sort((a, b) => a.v - b.v);
  let last = -99, row = 0;
  return live.map(m => {
    row = m.v - last < 22 ? row + 1 : 0;
    last = m.v;
    return { ...m, row };
  });
}
