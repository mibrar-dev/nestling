DIAGNOSIS (orchestrator rendered design/pip-v2/B/poses/s3_eating_4.svg, s3_sleepy_3.svg, s3_proud_2.svg at 400 px): face.mjs output is symmetric, but the FACE GROUP is rotated by θ while the head/body/crest stay upright (or rotated by a different angle/pivot). Result: in eating the eyes are tilted ~25° and the beak slides toward the bottom-left of the head; in proud the face is shifted right so one eye sits on the head edge; in sleepy the face is tilted inside an upright head.
FIX:
1. A head tilt must rotate head + crest + face TOGETHER as one group around the NECK pivot (bottom-centre of the head ellipse), never the face alone. Or simplest: set θ = 0 for the face and express tilt only via the shared head group.
2. The face's (cx, cy, r) must come from the head ellipse of THAT pose after any head transform, so the eyes always sit inside the head with equal margins on both sides.
3. Max head tilt ±12°.
4. Add an automated check to qa.mjs: for every pose, the face group's bounding-box centre must be within 4% of the head centre horizontally, and both eye centres must be inside the head ellipse. Fail the build if not.
Rebuild every pose, re-render all boards, then render s3_eating_4, s3_sleepy_3, s3_proud_2, s4_eating_4 at 400 px into design/pip-v2/B/FACE_CHECK.png and READ it. Reply only when all four look clean.
