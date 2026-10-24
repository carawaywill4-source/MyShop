# Tripo brief: Kessler GT6 sport sedan

Goal: an unbadged, G80-class German performance sedan that is clearly *inspired by* that segment but is not a copy of any real car, especially its grille.

## Prompt (text to 3D)

```
A realistic modern high-performance four-door sport sedan, German super-sedan proportions:
long low hood with a raised power dome, short front overhang, wide flared front and rear
fenders, sharp shoulder crease line, sloping fastback roofline, small ducktail trunk lip,
gloss black side skirts, slim angular LED headlights, a single wide horizontal hexagon-mesh
grille (one opening, not two), large vertical side air intakes, carbon front splitter,
L-shaped slim tail lights, four round exhaust tips, rear diffuser, 19-inch multi-spoke dark
alloy wheels with low-profile tyres and blue brake calipers. Metallic deep green paint,
tinted windows. No logos, no badges, no text, no license plate text. Clean production-car
surfaces, studio quality, symmetrical.
```

Negative prompt (if available):

```
logo, badge, emblem, text, kidney grille, split grille, cartoon, toy, low poly, exaggerated,
damaged, broken, asymmetric, people, background
```

## Settings

- Mode: text to 3D. Don't use a photo of a real BMW as the image input; that would copy its design.
- Highest quality / "Ultra" model if your plan has it. PBR textures on, texture 2K.
- Generate 3–4 variations and pick the one whose side profile and front look best.
- Export: **GLB**, PBR, about 50k–150k faces. Quad remesh is fine but not required.

## Licence check before we use it

- Tripo's terms depend on your plan. Free-tier generations may be public and carry attribution or non-commercial limits; paid plans generally allow private, commercial use. Check your plan's current terms and tell me what they say. I'll record it in `docs/ASSET_REGISTER.md`.

## Hand-off

Save the `.glb` anywhere (Downloads is fine) and tell me the filename. I will:

1. Install Blender (free) with your OK, then split the model into body, hood, four wheels, glass and lights, and set the pivots (hood hinge, wheel centres).
2. Scale it to 4.79 m and fit it on the lift pads, with the engine bay behind the hood.
3. Clean up the "AI look" where I can: symmetry, flatten melted details, replace the wheels with our authored wheels if theirs are mushy.
4. Render the same review shots and iterate with you until you like it.
