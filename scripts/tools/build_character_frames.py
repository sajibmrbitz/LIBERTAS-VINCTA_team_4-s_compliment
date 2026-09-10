"""Rebuild Godot SpriteFrames from the supplied sheets (Python stdlib only)."""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
DIRECTIONS = ('s', 'sw', 'w', 'nw', 'n', 'ne', 'e', 'se')


def build(output, clips):
    textures, regions, animations = {}, [], []
    for action, direction, path, row, fps, loop in clips:
        data = (ROOT / path).read_bytes()
        width, height = struct.unpack('>II', data[16:24])
        assert width % 256 == height % 256 == 0, path
        if path not in textures:
            textures[path] = str(len(textures) + 1)
        texture_id = textures[path]
        frames = []
        columns = width // 256
        cells = [(x, row) for x in range(columns)] if row is not None else [
            (x, y) for y in range(height // 256) for x in range(columns)]
        for x, y in cells:
            frame_id = f'frame_{len(regions)}'
            regions.append(f'[sub_resource type="AtlasTexture" id="{frame_id}"]\natlas = ExtResource("{texture_id}")\nregion = Rect2({x * 256}, {y * 256}, 256, 256)')
            frames.append('{"duration": 1.0, "texture": SubResource("' + frame_id + '")}')
        animations.append('{"frames": [' + ',\n'.join(frames) + '],\n"loop": ' + str(loop).lower() + f', "name": &"{action}_{direction}", "speed": {fps}.0' + '}')
    text = f'[gd_resource type="SpriteFrames" load_steps={len(textures) + len(regions) + 1} format=3]\n\n'
    text += '\n'.join(f'[ext_resource type="Texture2D" path="res://{path}" id="{key}"]'
                      for path, key in textures.items()) + '\n\n' + '\n\n'.join(regions)
    text += '\n\n[resource]\nanimations = [' + ',\n'.join(animations) + ']\n'
    (ROOT / output).write_text(text, encoding='utf-8')


if __name__ == '__main__':
    build('scenes/player/female_frames.tres', [
        (action, direction, f'ifat/female/{action}.png', row, 12, action in ('idle', 'walk', 'run'))
        for action in ('idle', 'walk', 'run', 'interact', 'unlock', 'pickup', 'flashlight', 'damage', 'stagger', 'death')
        for row, direction in enumerate(DIRECTIONS)
    ])
    # Asset angle 0 faces south; 090 faces east. Each sheet is row-major.
    angles = ('0', '315', '270', '225', '180', '135', '090', '045')
    build('scenes/enemy/zombie_frames.tres', [
        (action.lower() if action != 'Attack1' else 'attack', direction,
         f'zombie/Skin2_x256_Spritesheets/x256_Spritesheets/{action}/{action} Body {angle}.png',
         None, fps, action != 'Attack1')
        for action, fps in (('Idle', 12), ('Walk', 20), ('Run', 24), ('Attack1', 20))
        for direction, angle in zip(DIRECTIONS, angles)
    ])
