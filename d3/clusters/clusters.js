// Código para hacer clusters y nubes de palabras
// Datos
var data = [{
    clust: {
	number: "1",
	words: {
	    word: {
		number: "1",
		text: "rana",
		freq: 10,
		x: 12,
		y: 234
	    },
	    word: {
		number: "2",
		text: "lagartija",
		freq: 25,
		x: 54,
		y: 12

	    },
	    word: {
		number: "3",
		text: "serpiente",
		freq: 42,
		x: 98,
		y: 41
	    },
	    word: {
		number: "4",
		text: "cocodrilo",
		freq: 54,
		x: 123,
		y: 54
	    },
	    word: {
		number: "5",
		text: "caiman",
		freq: 78,
		x: 51,
		y: 90
	    }
	}
    },
    clust: {
	number: "2",
	words: {
	    word: {
		number: "1",
		text: "violeta",
		freq: 15,
		x: 1,
		y: 54
	    },
	    word: {
		number: "2",
		text: "amarillo",
		freq: 20,
		x: 13,
		y: 67
	    },
	    word: {
		number: "3",
		text: "verde",
		freq: 3,
		x: 18,
		y: 90
	    },
	    word: {
		number: "4",
		text: "anaranjado",
		freq: 7,
		x: 334,
		y: 98
	    },
	    word: {
		number: "5",
		text: "esmeralda",
		freq: 15,
		x: 65,
		y: 12
	    }
	}
    },
    clust: {
	number: "3",
	words: {
	    word: {
		number: "1",
		text: "python",
		freq: 12,
		x: 54,
		y: 12
	    },
	    word: {
		number: "2",
		text: "R",
		freq: 42,
		x: 54,
		y: 12
	    },
	    word: {
		number: "3",
		text: "JS",
		freq: 65,
		x: 89,
		y: 34
	    }
	}
    }
}];

// Márgenes y variables globales
var margin = {
    top: 40,
    left: 40,
    right: 40,
    bottom: 40
},
    h = window.innerHeight,
    w = window.innerWidth;

// Crear SVG
var svg = d3.select("body")
    .append("svg")
    .attr({
	height:h,
	width:w
    })

// Crear Escalas
var color_scale = d3.scale.ordinal()
    .domain(function(d){return data.clust.number;})
    .range(["#3F51B5","#2196F3","#FFC107"])

var size_scale = d3.scale.linear()
    .domain(0, d3.max(data, function(d){ return d.clust.words.word.freq;}))
