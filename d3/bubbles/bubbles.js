// Generamos valores para la ventana
var margin = {top:80, right:80, left:80, bottom:80};
// Generamos datos de manera aleatoria
var data = [];
for (var i = 0; i < 1000; i++) {
    data[i] = Math.random();
}
// Generamos svg contenedor
var svg = d3.select("body")
    .append("svg")
    .attr({
	width: window.innerWidth,
	height: window.innerHeight
    })

// Generamos funciones
// Explotar:
// La estrella seleccionada crece hasta explotar.
var xplode = function() {
	var rect = d3.select(this);
	var r_class = rect.attr('class');
	var x = rect.attr('x');
	var y = rect.attr('y');
	if (r_class == 'circle') {
	    rect.transition()
		.duration(500)
		.attr('rx', 0)
		.attr('ry', 0)
		.attr('fill', '#FFFF00')
		.attr('class', 'rectangle');
	} else {
	    rect.transition()
		.duration(500)
		.attr('rx', scale_s)
		.attr('ry', scale_s)
		.attr('fill', '#FFFFFF')
		.attr('class', 'circle');
	}
    }

// Vibrar
var vibe = function() {
    var rect = d3.select(this);
    var r_class = rect.attr('class');
    var x = rect.attr('x');
    var y = rect.attr('y');
    // Agregamos distorsión.
    var sig_x = Math.pow(-1, Math.floor(Math.random() * 10) % 2);
    var sig_y = Math.pow(-1, Math.floor(Math.random() * 10) % 2);
    var new_x = +x + +Math.random()*50*sig_x;
    var new_y = +y + +Math.random()*50*sig_y;
    rect.attr('x',new_x)
	.attr('y',new_y);
}

var col_col = function(){
    var circ = d3.select(this);
    var  c_class  = circ.attr('class');
    var x = circ.attr('x');
    var y = circ.attr('y');
    // Agregamos distorsión.
    var sig_x = Math.pow(-1, Math.floor(Math.random() * 10) % 2);
    var sig_y = Math.pow(-1, Math.floor(Math.random() * 10) % 2);
    var new_x = +x + +Math.random()*50*sig_x;
    var new_y = +y + +Math.random()*50*sig_y;
    circ.attr('x',new_x)
	.attr('y',new_y);
    if(c_class == 'circle'){
	circ.attr('fill', scale_c_2)
	    .attr('class','circ_b');
    }else if(c_class == 'circ_b'){
	circ.attr('fill', scale_c_3)
	    .attr('class','circ_r');
    }else if(c_class == 'circ_r'){
	circ.attr('fill', scale_c_4)
	    .attr('class','circ_g');
    }else if(c_class == 'circ_g'){
	circ.attr('fill', scale_c_5)
	    .attr('class','circ_p');
    }else if(c_class == 'circ_p'){
	circ.attr('fill', scale_c_1)
	    .attr('class','circle');
    }
}
// Elaboramos escalas para los distintos atributos
// de los circángulos.
var scale_h = d3.scale.linear()
    .domain([0, d3.max(data)])
    .range([margin.top, window.innerHeight - margin.bottom])

var scale_w = d3.scale.linear()
    .domain([0, 2000])
    .range([margin.left, window.innerWidth - margin.right])

var scale_s = d3.scale.linear()
    .domain([0, d3.max(data)])
    .range([0, 20])

var scale_c_1 = d3.scale.linear()
    .domain([0,d3.max(data)])
    .range(['#FFE57F','#FFAB00'])

var scale_c_2 = d3.scale.linear()
    .domain([0,d3.max(data)])
    .range(['#BBDEFB','#0D47A1'])

var scale_c_3 = d3.scale.linear()
    .domain([0,d3.max(data)])
    .range(['#FF8A80','#D50000'])

var scale_c_4 = d3.scale.linear()
    .domain([0,d3.max(data)])
    .range(['#CCFF90','#76FF03'])

var scale_c_5 = d3.scale.linear()
    .domain([0,d3.max(data)])
    .range(['#EA80FC','#D500F9'])


// Generamos cuadrados
var rects = svg.selectAll("rect")
    .data(data)
    .enter()
    .append("rect")
    .attr({
	rx: scale_s,

	ry: scale_s,

	x: function(d, i) {
	    return scale_w(i * 2)
	},
	y: function(d, i) {
	    return scale_h(Math.random())
	},
	width: scale_s,
	height: scale_s,
	fill: scale_c_1,
	class: 'circle'
    })
    .on('mouseover', col_col)
