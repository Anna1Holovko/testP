({
	closeLegend : function(c, e, h) {
        e.stopPropagation();
		c.set('v.isLegendOpen', false);
	},
    openLegend: function(c,e,h) {
        e.stopPropagation();
		c.set('v.isLegendOpen', true);
	}
})