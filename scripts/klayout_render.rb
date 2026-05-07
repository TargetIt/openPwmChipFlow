# Render PWM chip: full chip + each layer separately
app = RBA::Application.instance
mw = app.main_window

RUN = '/chip/openlane/pwm_ctrl/runs/RUN_2026.05.04_17.02.01'
GDS = RUN + '/results/final/gds/pwm_ctrl.gds'
OUT = '/chip/delivery/images'
Dir.mkdir(OUT) unless Dir.exist?(OUT)

puts "Loading GDS: #{GDS}"
mw.load_layout(GDS, 0)
lv = mw.current_view
cv = lv.active_cellview
cell = cv.layout.top_cell
lv.select_cell(cv.cell_index, 0)
bbox = cell.bbox
puts "Cell: #{cell.name}, Size: #{bbox.width*cv.layout.dbu}um x #{bbox.height*cv.layout.dbu}um"

# Helper: show only layers matching given (gds_layer, gds_datatype) pairs
def show_matching_layers(lv, specs)
  lv.each_layer do |lp|
    matched = specs.any? { |layer, dt| lp.source_layer == layer && lp.source_datatype == dt }
    lp.visible = matched
  end
end

# Helper: render
def render(lv, path, label)
  lv.save_image(path, 2400, 1800)
  puts "  OK #{label}"
end

# ===== GDS layer mapping (Sky130) =====
# 67/20=li1, 67/44=licon1, 68/20=met1, 68/44=via1,
# 69/20=met2, 69/44=via2, 70/20=met3, 70/44=via3,
# 71/20=met4, 71/44=via4, 72/20=met5, 235/4=outline

# ==== 1. Full chip (all layers) ====
puts "\n=== 1. Full chip ==="
lv.zoom_fit
lv.save_image(OUT + '/01_full_chip.png', 2400, 1800)
puts "  OK full_chip.png"

# ==== 2. Per-layer renders ====
# Each spec: [filename, [[gds_layer, gds_datatype], ...]]
layer_specs = [
  ['02_li1',                [[67,20]]],
  ['03_licon1',             [[67,44]]],
  ['04_met1',               [[68,20]]],
  ['05_via1',               [[68,44]]],
  ['06_met2',               [[69,20]]],
  ['07_via2',               [[69,44]]],
  ['08_met3',               [[70,20]]],
  ['09_via3',               [[70,44]]],
  ['10_met4',               [[71,20]]],
  ['11_via4',               [[71,44]]],
  ['12_met5',               [[72,20]]],
  ['13_all_labels_outline', [[67,5],[68,5],[69,5],[70,5],[71,5],[72,5],
                              [67,16],[68,16],[69,16],[70,16],[71,16],[72,16],
                              [235,4]]],
  ['14_met1_to_met2',       [[68,20],[68,44],[69,20]]],
  ['15_met2_to_met3',       [[69,20],[69,44],[70,20]]],
  ['16_met3_to_met5',       [[70,20],[70,44],[71,20],[71,44],[72,20]]],
]

layer_specs.each do |name, specs|
  puts "\n=== #{name} ==="
  show_matching_layers(lv, specs)
  lv.zoom_fit
  render(lv, OUT + "/#{name}.png", name)
end

# ==== 3. Detail views (all layers visible) ====
puts "\n=== Detail views ==="
show_matching_layers(lv, [])  # show nothing first, then all
lv.each_layer { |lp| lp.visible = true }  # show all
lv.zoom_fit
w = bbox.width
h = bbox.height

# Top region detail
box = RBA::DBox.new(bbox.left + w*0.0, bbox.bottom + h*0.65,
                    bbox.left + w*0.35, bbox.bottom + h*1.0)
lv.zoom_box(box)
render(lv, OUT + '/17_detail_top.png', 'detail_top')

# Center detail
box = RBA::DBox.new(bbox.left + w*0.35, bbox.bottom + h*0.35,
                    bbox.left + w*0.65, bbox.bottom + h*0.65)
lv.zoom_box(box)
render(lv, OUT + '/18_detail_center.png', 'detail_center')

# Transistor-level (li1+licon1+met1 only)
show_matching_layers(lv, [[67,20],[67,44],[68,20]])
lv.zoom_fit
box = RBA::DBox.new(bbox.left + w*0.15, bbox.bottom + h*0.4,
                    bbox.left + w*0.30, bbox.bottom + h*0.6)
lv.zoom_box(box)
render(lv, OUT + '/19_detail_transistor.png', 'detail_transistor')

puts "\n=== All done! ==="
