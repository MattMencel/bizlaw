// THROWAWAY — prototype build for https://github.com/MattMencel/bizlaw/issues/299
//
// Renders the cast twice — avataaars busts for register A, pixel-art busts for
// register B — and concatenates src/ into a single index.html you can double-click.
// Register C has no cast; that is its argument.
//
// Art provenance: fangpenlin/avataaars (MIT, (c) 2017 Pablo Stanley, Fang-Pen Lin)
// and DiceBear pixel-art (CC0), both rendered through @dicebear/core
// (MIT, (c) Florian Koerner).
//
//   npm install && npm run build

import { readFileSync, writeFileSync } from "node:fs";
import { createAvatar } from "@dicebear/core";
import { avataaars, pixelArt } from "@dicebear/collection";

// Two Reaction Bands, and only the Team's own Client is expressive (CONTEXT.md).
// Marcus and Eleanor carry one authored expression each, fixed for the Simulation.
const AVATAAARS = {
  dana: {
    base: {
      top: ["longButNotTooLong"], hairColor: ["2c1b18"], skinColor: ["d08b5b"],
      clothing: ["blazerAndShirt"], clothesColor: ["3c4f5c"],
      facialHairProbability: 0, accessoriesProbability: 0,
    },
    faces: {
      firm:  { eyebrows: "defaultNatural",      eyes: "default", mouth: "serious"   },
      ready: { eyebrows: "flatNatural",         eyes: "side",    mouth: "sad"       },
    },
  },
  marcus: {
    base: {
      top: ["shortFlat"], hairColor: ["1a1a1a"], skinColor: ["ae5d29"],
      clothing: ["blazerAndShirt"], clothesColor: ["262e33"],
      facialHair: ["beardLight"], facialHairProbability: 100, facialHairColor: ["1a1a1a"],
      accessoriesProbability: 0,
    },
    faces: { fixed: { eyebrows: "flatNatural", eyes: "default", mouth: "serious" } },
  },
  eleanor: {
    base: {
      top: ["bun"], hairColor: ["b58143"], skinColor: ["edb98a"],
      clothing: ["blazerAndSweater"], clothesColor: ["5c4033"],
      accessories: ["prescription02"], accessoriesProbability: 100,
      accessoriesColor: ["262e33"], facialHairProbability: 0,
    },
    faces: { fixed: { eyebrows: "defaultNatural", eyes: "default", mouth: "default" } },
  },
};

// The same cast at 32-48px. The expression vocabulary is mouth + eyes and nothing
// else — which is the cost register B is here to make visible.
const PIXEL = {
  dana: {
    base: { hair: ["long13"], hairColor: ["2c1b18"], skinColor: ["d08b5b"],
            clothing: ["variant02"], clothingColor: ["3c4f5c"],
            beardProbability: 0, glassesProbability: 0, hatProbability: 0 },
    faces: { firm: { eyes: "variant05", mouth: "sad04" },
             ready: { eyes: "variant01", mouth: "sad09" } },
  },
  marcus: {
    base: { hair: ["short06"], hairColor: ["1a1a1a"], skinColor: ["ae5d29"],
            clothing: ["variant05"], clothingColor: ["262e33"],
            beard: ["variant03"], beardProbability: 100,
            glassesProbability: 0, hatProbability: 0 },
    faces: { fixed: { eyes: "variant02", mouth: "sad01" } },
  },
  eleanor: {
    base: { hair: ["long06"], hairColor: ["b58143"], skinColor: ["edb98a"],
            clothing: ["variant09"], clothingColor: ["5c4033"],
            glasses: ["dark01"], glassesProbability: 100,
            beardProbability: 0, hatProbability: 0 },
    faces: { fixed: { eyes: "variant04", mouth: "sad01" } },
  },
};

// Drop width/height on the ROOT tag only so CSS can size it; keep the viewBox.
// Stripping them globally guts the masks and the avatar renders blank.
const loose = svg => svg.replace(/^<svg[^>]*>/, m => m.replace(/\s(width|height)="[^"]*"/g, ""));

function render(style, spec, extra) {
  const out = {};
  for (const [who, { base, faces }] of Object.entries(spec)) {
    out[who] = {};
    for (const [state, face] of Object.entries(faces)) {
      out[who][state] = loose(createAvatar(style, {
        seed: who, backgroundColor: ["transparent"], ...extra, ...base,
        ...Object.fromEntries(Object.entries(face).map(([k, v]) => [k, [v]])),
      }).toString());
    }
  }
  return out;
}

const art = {
  avataaars: render(avataaars, AVATAAARS, { style: ["default"], nose: ["default"] }),
  pixel: render(pixelArt, PIXEL, {}),
};

const read = p => readFileSync(`src/${p}`, "utf8");
const html = read("shell.html")
  .replace("/*ART*/", `window.ART = ${JSON.stringify(art)};`)
  .replace("/*CSS*/", ["a-boardroom.css", "b-console.css", "c-paper.css"].map(read).join("\n"))
  .replace("/*JS*/", ["beat.js", "a-boardroom.js", "b-console.js", "c-paper.js", "switch.js"]
    .map(f => `// ---- ${f}\n${read(f)}`).join("\n"));

writeFileSync("index.html", html);
console.log(`index.html written — ${(Buffer.byteLength(html) / 1024).toFixed(0)} KB`);
