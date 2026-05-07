"""Analyze GDS: layers, cells, dimensions."""
import klayout.db as db, os, glob

runs = sorted(glob.glob('/chip/openlane/pwm_ctrl/runs/RUN_*'))
latest = runs[-1]
gds = latest + '/results/final/gds/pwm_ctrl.gds'
print(f'Run: {os.path.basename(latest)}')

ly = db.Layout()
ly.read(gds)
cell = ly.top_cell()
bbox = cell.bbox()
w_um = bbox.width() * ly.dbu
h_um = bbox.height() * ly.dbu
print(f'Top cell: {cell.name}')
print(f'Size: {w_um:.1f}um x {h_um:.1f}um = {w_um*h_um/1e6:.3f} mm^2')
print(f'Child cells: {len(list(ly.each_cell()))}')

print('\n=== Layers & Shape Counts ===')
layers_info = []
for li in sorted(ly.layer_indices()):
    lp = ly.get_info(li)
    gds_layer = lp.layer if lp else li
    gds_datatype = lp.datatype if lp else 0
    count = cell.shapes(li).size() if cell.shapes(li) else 0
    if count > 0 or (lp and hasattr(lp, 'name') and lp.name):
        name = f'L{gds_layer}/DT{gds_datatype}'
        layers_info.append((li, gds_layer, gds_datatype, name, count))
        print(f'  ly_idx={li:3d}  GDS({gds_layer}/{gds_datatype})  {name:40s}  top_shapes={count}')

print(f'\nTotal layers with shapes: {len(layers_info)}')
