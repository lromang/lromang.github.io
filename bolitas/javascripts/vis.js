var BubbleChart, root,
    __bind = function(fn, me) {
        return function() {
            return fn.apply(me, arguments);
        };
    };

BubbleChart = (function() {
    function BubbleChart(data) {
        this.do_filter = __bind(this.do_filter, this);
        this.use_filters = __bind(this.use_filters, this);
        this.hide_details = __bind(this.hide_details, this);
        this.show_details = __bind(this.show_details, this);
        this.hide_labels = __bind(this.hide_labels, this);
        this.display_labels = __bind(this.display_labels, this);
        this.move_towards_group = __bind(this.move_towards_group, this);
        this.display_by_group = __bind(this.display_by_group, this);
        this.move_towards_group_center = __bind(this.move_towards_group_center, this);
        this.group_by = __bind(this.group_by, this);
        this.get_distinct_values = __bind(this.get_distinct_values, this);
        this.color_by = __bind(this.color_by, this);
        this.remove_colors = __bind(this.remove_colors, this);
        this.sort = __bind(this.sort, this);
        this.get_color_map = __bind(this.get_color_map, this);
        this.get_color_map_lookup_set = __bind(this.get_color_map_lookup_set, this);
        this.get_color_map_achievement = __bind(this.get_color_map_achievement, this);
        this.move_towards_center = __bind(this.move_towards_center, this);
        this.display_group_all = __bind(this.display_group_all, this);
        this.start = __bind(this.start, this);
        this.create_vis = __bind(this.create_vis, this);
        this.create_nodes = __bind(this.create_nodes, this);
        this.data = data;
        this.width = 1140;
        this.height = 600;
        this.tooltip = CustomTooltip("my_tooltip", 240);
        this.center = {
            x: this.width / 2,
            y: this.height / 2
        };
        this.layout_gravity = -0.01;
        // DISPERSION ENTRE NODOS
        this.damper = 0.8;
        this.vis = null;
        this.force = null;
        this.circles = null;
        this.nodes = [];
        this.currentCircles = [];
        var num_max_indicadores;
        num_max_indicadores = d3.max(this.data, function(d) {
            return parseInt(d.Likes); //.Likes.substr(1));
            //return parseInt(d.value_amount); //.Likes.substr(1));
        });
        //console.log(num_max_indicadores);
        // TAMAÑO DE LOS NODOS
        this.radius_scale = d3.scale.pow().exponent(0.3).domain([1, num_max_indicadores]).range([1, 50]); //.domain([1, 4.5]).range([10, 30]);
        this.create_nodes();
        this.create_vis();
        this.circles.style("fill", '#00cc99');
    }
    var nodeColors;
    nodeColors = d3.scale.category20();



    // FUNCION PARA HACER LAS BUSQUEDAS
    BubbleChart.prototype.buscar = function(filterText) {
        filterText = filterText.toLowerCase();
        if (filterText !== "") {
            var filtrados = this.data.filter(function(d) {
                if(d["Page name"] !== null){
                    return d["Page name"].toLowerCase().indexOf(filterText) !== -1;
                }
            });
            if (Object.keys(filtrados).length !== 0) {
                var names = {};
                filtrados.forEach(function(x) {
                    names[x["Page name"]] = "#00cc99";
                    //names[x.identifier_legalname] = "#00cc99";
                }); //!!!
                this.circles.transition().duration(600).style("fill", function(d) {
                    return names[d.original['Page name']]; //!!!
                    //return names[d.original.idenfier_legalname];
                });
                hide_color_chart();
            } else {
                alert("La búsqueda no produjo resultados");
                color_by($('#color-everything-by').val());
            }
        } else {
            color_by($('#color-everything-by').val());
        }
    };


    BubbleChart.prototype.create_nodes = function() {
        var _this = this;
        this.data.forEach(function(d, i) {
            var node;
            var radius = _this.radius_scale(_this.getRadius(d));
            node = {
                id: i,
                original: d,
                radius: radius,
                value: radius,
                x: Math.random() * _this.width,
                y: Math.random() * _this.height
            };
            _this.nodes.push(node);
        });
    };
    // CREACIÓN DE LOS NODOS, AQUÍ ESTÁN LOS EVENTOS PARA MOSTRAR LA INFORMACIÓN EN CADA NODO
    BubbleChart.prototype.create_vis = function() {
        var that,
            _this = this;
        /*this.vis = d3.select("#vis").append("svg").attr("width", this.width).attr("height", this.height).attr("id", "svg_vis");*/
        this.vis = d3.select("#vis").append("svg").attr("id", "svg_vis").attr("preserveAspectRatio", "xMinYMin meet").attr("viewBox", "0 0 1140 600");
        this.circles = this.vis.selectAll("circle").data(this.nodes, function(d) {
            return d.id;
        });
        that = this;
        this.circles.enter().append("circle").attr("r", 100).style("fill", function(d) {
            return '#00cc99';
        })/*.attr("stroke-width", 2).attr("stroke", function(d) {
            return '#404040';
        })*/.attr("stroke", "none")
            .attr("id", function(d) {
                return "bubble_" + d.id;
            }).on("mouseover", function(d, i) {
            return that.show_details(d, i, this);
        }).on("mouseout", function(d, i) {
            return that.hide_details(d, i, this);
        })/*.on('click', function (d, i) {
            //redirige al detalle del contrato
            window.location.href = '/contratacionesabiertas/contrato/'+d.original['cpid']+'/adjudicacion';
        });*/

        this.circles.transition().duration(2000).style("fill-opacity", 0.55).attr("opacity", 2).attr("r", function(d) {
            return d.radius;
        });
    };
    BubbleChart.prototype.charge = function(d) {
        if (d.radius === 0) {
            return 0;
        }
        return -Math.pow(d.radius, 2);
    };
    BubbleChart.prototype.start = function() {
        this.force = d3.layout.force().nodes(this.nodes).size([this.width, this.height]);
        return this.circles.call(this.force.drag); // Efecto de arrastrar
    };
    BubbleChart.prototype.display_group_all = function() {
        var _this = this;
        this.hide_labels();
        this.force.gravity(this.layout_gravity).charge(this.charge).friction(0.8).on("tick", function(e) {
            _this.circles.each(_this.move_towards_center(e.alpha)).attr("cx", function(d) {
                return d.x;
            }).attr("cy", function(d) {
                return d.y;
            });
        });
        this.force.start();
    };
    BubbleChart.prototype.move_towards_center = function(alpha) {
        var _this = this;
        return function(d) {
            d.x = d.x + (_this.center.x - d.x) * (_this.damper + 0.02) * alpha;
            return d.y = d.y + (_this.center.y - d.y) * (_this.damper + 0.02) * alpha;
        };
    };
    // FUNCIÓN PARA MAPAEAR LOS COLORES, SE PUEDEN CAMBIAR...
    BubbleChart.prototype.get_color_map_lookup_set = function(allValuesArray) {
        var baseArray, color_map, index, value, _i, _len;
        baseArray = [
            '#00cc99', //adjudicación directa
            'gray', // asa
            '#ffcc00', //convenio de colaboración
            '#663399', // Invitación a 3
            '#ff6600', //licitación
            '#ff6666',
            "#0000D9",
            "#FF00FF",
            "#FF0033",
            "#FFCC66",
            "#66CC33",
            "#33FFCC", "#00A0AA", "#FFCCFF", "#FF9933", "#99FF99", "#00BB00", "#CCFFCC", "#333333", "#CCCCCC", "#99CCCC", "#FF0000"];
        index = 0;
        color_map = {};
        for (_i = 0, _len = allValuesArray.length; _i < _len; _i++) {
            value = allValuesArray[_i];
            color_map[value] = baseArray[index];
            index = index + 1;
            if (index >= baseArray.length) {
                index = 0;
            }
        }
        return color_map;
    };
    BubbleChart.prototype.get_color_map = function(allValuesArray) {
        return this.get_color_map_lookup_set(allValuesArray);
    };
    BubbleChart.prototype.sort = function(allValuesArray) {
        allValuesArray.sort();
    };
    BubbleChart.prototype.remove_colors = function() {
        this.circles.transition().duration(600).style("fill", "#00cc99");
        hide_color_chart();
    };
    BubbleChart.prototype.color_by = function(what_to_color_by) {
        var allValuesArray, color_mapper,
            _this = this;
        this.what_to_color_by = what_to_color_by;
        allValuesArray = this.get_distinct_values(what_to_color_by);
        color_mapper = this.get_color_map(allValuesArray);
        // Agrega DIV para mostrar los colores
        show_color_chart(what_to_color_by, color_mapper);
        var test = this.circles.transition().duration(600).style("fill", function(d) {
            return color_mapper[d.original[what_to_color_by]];
        });
    };


    BubbleChart.prototype.get_distinct_values = function(what) {
        var allValues, allValuesArray, key, value,
            _this = this;
        allValues = {};
        this.nodes.forEach(function(d) {
            var value;
            value = d.original[what];
            var flag = false;
            var filterers = $('.filter_block input').filter(function() {
                return !this.checked;
            }).each(function() {
                if (value == this.value) {
                    flag = true; // Es igual por lo tanto no se guarda
                }
            });

            if (!flag) {
                allValues[value] = true;
            }
        });
        allValuesArray = [];
        for (key in allValues) {
            value = allValues[key];
            allValuesArray.push(key);
        }
        this.sort(allValuesArray);
        return allValuesArray;
    };


    BubbleChart.prototype.group_by = function(what_to_group_by) {
        var allValuesArray, numCenters, position, total_slots,
            _this = this;
        this.what_to_group_by = what_to_group_by;
        allValuesArray = this.get_distinct_values(what_to_group_by);
        numCenters = allValuesArray.length;
        this.group_centers = {};
        this.group_labels = {};
        position = 1.8; // Posicion dentro del DIV
        total_slots = allValuesArray.length + 2;
        allValuesArray.forEach(function(i) {
            var x_position;
            x_position = _this.width * position / total_slots;
            _this.group_centers[i] = {
                x: x_position,
                y: _this.height / 1.9 // Separación entre las etiquetas y los nodos
            };
            _this.group_labels[i] = x_position;
            position = position + 1;
        });
        //console.log(this.group_labels);
        this.hide_labels();
        this.force.gravity(this.layout_gravity).charge(this.charge).friction(0.9).on("tick", function(e) {
            _this.circles.each(_this.move_towards_group_center(e.alpha)).attr("cx", function(d) {
                return d.x;
            }).attr("cy", function(d) {
                return d.y;
            });
        });
        this.force.start();
        this.display_labels();
    };


    BubbleChart.prototype.move_towards_group_center = function(alpha) {
        var _this = this;
        return function(d) {
            var target, value;
            value = d.original[_this.what_to_group_by];
            target = _this.group_centers[value];
            if (typeof target == 'undefined') return;
            d.x = d.x + (target.x - d.x) * (_this.damper + 1) * alpha * 1;
            d.y = d.y + (target.y - d.y) * (_this.damper + 0.09) * alpha * 1.1;
        };
    };


    BubbleChart.prototype.move_towards_group = function(alpha) {
        var _this = this;
        return function(d) {
            var target;
            target = _this.group_centers[d.group];
            d.x = d.x + (target.x - d.x) * (_this.damper + 0.7) * alpha * 1.1;
            d.y = d.y + (target.y - d.y) * (_this.damper + 0.7) * alpha * 1.1;
        };
    };


    BubbleChart.prototype.display_labels = function() {
        var label_data, labels,
            _this = this;
        var group_labels = this.group_labels;
        _this.hide_labels();
        label_data = d3.keys(group_labels);
        //console.log(group_labels);
        labels = this.vis.selectAll(".top_labels").data(label_data);
        labels.enter().append("text").attr("class", "top_labels").attr("width", 80).attr("x", function(d) {
            return group_labels[d];
        }).attr("y", 10).text(function(d) {
            return d;
        });
    };

    BubbleChart.prototype.hide_labels = function() {
        var labels;
        labels = this.vis.selectAll(".top_labels").remove();
    };

    BubbleChart.prototype.show_details = function(data, i, element) {
        var content, key, title, value, _ref;
        d3.select(element)./*attr("stroke", "black").*/style("fill-opacity", 0.85).style("cursor", "pointer");
        content = "Page name:<br><b>"+data.original['Page name']+"</b>"; //.Elemento;
        //content = data.original.identifier_legalname; //.Elemento;
        this.tooltip.showTooltip(content, d3.event);
    };

    BubbleChart.prototype.hide_details = function(data, i, element) {
        d3.select(element)./*attr("stroke", "#404040").*/style("fill-opacity", 0.55);
        this.tooltip.hideTooltip();
    };

    BubbleChart.prototype.use_filters = function(filters, targets) {
        var filteredCircles = this.nodes.filter(function(d) {
            var original = d.original;
            var flag = true;
            d.radius = d.value;
            for (var i = 0, len = filters.length; i < len; i++) {
                if (original[targets[i]] === filters[i]) {
                    d.radius = 0;
                    flag = false;
                    break;
                }
            }
            return flag;
        });
        this.do_filter();
        $('#group-everything-by').change();
    };

    BubbleChart.prototype.do_filter = function() {
        this.force.start();
        this.circles.transition().duration(2000).attr("r", function(d) {
            return d.radius
        });
    };

    BubbleChart.prototype.getRadius = function(node) {
        return node.Likes//.substr();
        //return node.value_amount.substr();
    };

    return BubbleChart;
})();
root = typeof exports !== "undefined" && exports !== null ? exports : this;


$(function() {
    var chart, render_chart, render_vis,
        _this = this;
    chart = null;

    render_vis = function(csv) {
        //console.log(csv[0]);
        render_filters_colors_and_groups(csv);
        render_chart(csv);
    };

    render_chart = function(csv) {
        chart = new BubbleChart(csv);
        chart.start();
        root.display_all();
    };

    root.display_all = function() {
        chart.display_group_all();
    };

    root.group_by = function(groupBy) {
        if (groupBy === '') {
            chart.display_group_all();
        } else {
            chart.group_by(groupBy);
        }
    };

    root.color_by = function(colorBy) {
        if (colorBy === '') {
            chart.remove_colors();
        } else {
            chart.color_by(colorBy);
        }
    };

    root.use_filters = function(filters, targets) {
        chart.use_filters(filters, targets);
    };

    root.display_labels = function() {
        chart.display_labels();
    };

    //d3.csv("/contratacionesabiertas/static/supplier_data.csv", render_vis);
    d3.json("data/final_bubble.json", function(error, result) {
      var data2 = [];
      for (i = 0; i < result.length; i += 1) {
        data2.push({
          //"Proveedor": result[i].page_name,
          "Page name": result[i].page_name,
          //"ID de contrato": result[i].contractid,
          "Education": result[i].education,
          "Gender": result[i].gender,
          "Hometown": result[i].hometown,
          "Likes": result[i].likes,
          //"cpid": 1//result[i].cpid
        });
      }
      render_vis(data2);
    });
    // Evento KEYUP para buscar, ACTIVA LA FUNCIÓN BUSCAR AL ESCRIBIR ALGO EN EL INPUT DE BUSCAR
    $("#buscar_bubble").keyup(function() {
        var searchTerm;
        searchTerm = $(this).val();
        return chart.buscar(searchTerm);
    });
});


function CustomTooltip(tooltipId, width){
    var tooltipId = tooltipId;
    $("body").append("<div class='tooltipBubble' id='"+tooltipId+"'></div>");

    if(width){
        $("#"+tooltipId).css("width", width);
    }

    hideTooltip();

    function showTooltip(content, event){
        $("#"+tooltipId).html(content);
        $("#"+tooltipId).show();

        updatePosition(event);
    }

    function hideTooltip(){
        $("#"+tooltipId).hide();
    }

    function updatePosition(event){
        var ttid = "#"+tooltipId;
        var xOffset = 20;
        var yOffset = 10;

        var ttw = $(ttid).width();
        var tth = $(ttid).height();
        var wscrY = $(window).scrollTop();
        var wscrX = $(window).scrollLeft();
        var curX = (document.all) ? event.clientX + wscrX : event.pageX;
        var curY = (document.all) ? event.clientY + wscrY : event.pageY;
        var ttleft = ((curX - wscrX + xOffset*2 + ttw) > $(window).width()) ? curX - ttw - xOffset*2 : curX + xOffset;
        if (ttleft < wscrX + xOffset){
            ttleft = wscrX + xOffset;
        }
        var tttop = ((curY - wscrY + yOffset*2 + tth) > $(window).height()) ? curY - tth - yOffset*2 : curY + yOffset;
        if (tttop < wscrY + yOffset){
            tttop = curY + yOffset;
        }
        $(ttid).css('top', tttop + 'px').css('left', ttleft + 'px');
    }

    return {
        showTooltip: showTooltip,
        hideTooltip: hideTooltip,
        updatePosition: updatePosition
    }
}
