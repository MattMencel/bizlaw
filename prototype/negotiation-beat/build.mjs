// THROWAWAY — prototype build for https://github.com/MattMencel/bizlaw/issues/264
//
// Renders the NPC cast as avataaars SVG (one file per character x expression) and
// inlines the whole lot into index.html, so the prototype is a single file you can
// double-click. Art provenance: fangpenlin/avataaars (MIT, (c) 2017 Pablo Stanley,
// Fang-Pen Lin), rendered through @dicebear/core (MIT, (c) 2026 Florian Koerner).
//
//   npm install && npm run build

import { readFileSync, writeFileSync } from "node:fs";
import { createAvatar } from "@dicebear/core";
import { avataaars } from "@dicebear/collection";

// Six states spanning the negotiation range. Composed from independent eyebrow /
// eye / mouth layers over one unchanged head — the mechanic #259 recommended.
const STATES = {
  neutral:   { eyebrows: "defaultNatural",       eyes: "default",   mouth: "serious"   },
  pleased:   { eyebrows: "raisedExcitedNatural", eyes: "happy",     mouth: "smile"     },
  wary:      { eyebrows: "sadConcernedNatural",  eyes: "squint",    mouth: "concerned" },
  skeptical: { eyebrows: "upDownNatural",        eyes: "side",      mouth: "disbelief" },
  insulted:  { eyebrows: "angryNatural",         eyes: "squint",    mouth: "grimace"   },
  resigned:  { eyebrows: "flatNatural",          eyes: "side",      mouth: "sad"       },
};

// Three NPCs. Business dress only — blazerAndShirt / blazerAndSweater /
// collarAndSweater are the only three garments in the library that read professional.
const CAST = {
  client: {
    top: ["longButNotTooLong"], hairColor: ["2c1b18"], skinColor: ["d08b5b"],
    clothing: ["blazerAndShirt"], clothesColor: ["3c4f5c"],
    facialHairProbability: 0, accessoriesProbability: 0,
  },
  counsel: {
    top: ["shortFlat"], hairColor: ["1a1a1a"], skinColor: ["ae5d29"],
    clothing: ["blazerAndShirt"], clothesColor: ["262e33"],
    facialHair: ["beardLight"], facialHairProbability: 100, facialHairColor: ["1a1a1a"],
    accessoriesProbability: 0,
  },
  defendant: {
    top: ["bun"], hairColor: ["b58143"], skinColor: ["edb98a"],
    clothing: ["blazerAndSweater"], clothesColor: ["5c4033"],
    accessories: ["prescription02"], accessoriesProbability: 100, accessoriesColor: ["262e33"],
    facialHairProbability: 0,
  },
};

const avatars = {};
for (const [who, look] of Object.entries(CAST)) {
  avatars[who] = {};
  for (const [state, face] of Object.entries(STATES)) {
    const svg = createAvatar(avataaars, {
      seed: who, style: ["default"], backgroundColor: ["transparent"],
      nose: ["default"], ...look,
      eyebrows: [face.eyebrows], eyes: [face.eyes], mouth: [face.mouth],
    }).toString();
    // Drop the fixed width/height on the ROOT tag only so CSS can size it; keep the
    // viewBox. Stripping them globally guts the masks and the avatar renders blank.
    avatars[who][state] = svg.replace(/^<svg[^>]*>/, m =>
      m.replace(/\s(width|height)="[^"]*"/g, ""));
  }
}

const html = readFileSync("template.html", "utf8").replace(
  "/*AVATARS*/",
  `window.AVATARS = ${JSON.stringify(avatars)};`
);
writeFileSync("index.html", html);

const kb = (Buffer.byteLength(html) / 1024).toFixed(0);
console.log(`index.html written — ${Object.keys(CAST).length} characters x ${Object.keys(STATES).length} states, ${kb} KB`);
