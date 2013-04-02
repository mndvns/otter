

# Template.home.rendered = ->
#   s = Session
# 
#   Session.set-default 'giant_tagset', Tagsets.find!.fetch!
#   Session.set-default 'giant_tag', Tags.find!.fetch!
# 
#   # data-tags   = Tags.find tagset: Session.get 'giant_tagset' .fetch!
# 
#   width = $ document .width!
#   height = 300
# 
# 
#   tagset = d3.select '.tagset' .append 'svg'
#     .attr 'width', width
#     .attr 'height', 500
#     .append 'g'
#     .attr 'transform', 'translate(32,' + (height / 2) + ')'
# 
#   Deps.autorun ->
# 
#     data-tagset = Session.get('giant_tagset')
# 
#     window.d3_text = text = tagset.select-all 'text'
#       .data data-tagset, (-> it)
# 
#     text.attr 'class', 'update'
#       .transition!
#       .duration 750
#       .attr 'x', (d,i) -> i * (width / 3)
#       .style 'fill', 'red'
# 
#     text.enter!append 'text'
#       .attr 'class', (d, i) ->
#         'update'
#       .attr 'dy', '.35em'
#       .attr 'y', 60
#       .attr 'x', (d,i)-> i * (width / 3)
#       .attr 'text-anchor', 'middle'
#       .style 'fill-opacity', 1e-6
#       .text (.name)
#       .transition!
#       .duration 750
#       .attr 'y', 0
#       .style 'fill-opacity', 1
# 
#     text.exit!
#       .transition!
#       .style 'fill-opacity', 0
#       .remove!
# 
#     text.on 'click', (d, i) ->
#       s.set 'giant_tag', (Tags.find 'tagset': d.name .fetch!)
# 
# 
# 
#   tag = d3.select '.tag' .append 'svg'
#     .attr 'width', width
#     .attr 'height', 200
#     .append 'g'
# 
#   Deps.autorun ->
# 
#     data-tag = Session.get 'giant_tag'
# 
#     text = tag.select-all 'text'
#       .data data-tag, (-> it)
# 
#     text.enter!append 'text'
#       .attr 'dy', '.35em'
#       .attr 'y', 60
#       .text (.name)
#       .transition!
#       .duration 750
#       .attr 'y', 0
#       .style 'fill-opacity', 1
# 
#     text.exit!
#       .transition!
#       .style 'fill-opacity', 0
#       .remove!


  # console.log \ASDASDASD, data-tags


  # window.update data-tagset
