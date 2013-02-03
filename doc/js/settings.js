function rrdgraph_load(h, a, d) {
    var f = new Date().getTime();
    var c = "",
        b = "";
    if (!d) {
        if (!h.is(".open")) {
            h.children().attr("src", "im/settings/settings_graphmask.png")
        }
        h.removeClass("closed").addClass("open");
        c = "&w=650&h=90&color1=00ff00&color2=ff0000&ts=" + f + ""
    } else {
        if (h.is(".open")) {
            h.children().attr("src", "im/settings/settings_graphmask_closed.png")
        }
        h.addClass("closed").removeClass("open");
        c = "&w=740&h=70";
        b = "-60px -20px no-repeat"
    }
    var g = "rrd.cgi?" + a + c;
    $("<img/>").attr("src", "rrd.cgi?" + a + c).load(function() {
        h.css("background", "url(" + g + ") " + b)
    })
}
var SBar = SBarBase.extend({});
sbar = new SBar();
$(document).ready(function() {
    $(".tip").tipTip()
});
