var SBar = Base.extend({
    constructor: function() {
        var a = this;
        this._trefresh = null;
        this._tasks = {};
        this._visible = false;
        setTimeout(function() {
            a.tasks_refresh()
        }, 500)
    },
    set_visible: function(b) {
        var a = $("#status_bar").children().length;
        if (!this._visible && a) {
            $("#fluid").css({
                bottom: "10px"
            });
            b.animate({
                bottom: "-2px"
            })
        } else {
            if (this._visible && !a) {
                b.animate({
                    bottom: "-35px"
                })
            }
        }
        this._visible = a
    },
    push_error: function(d) {
        var a = this;
        var b = $("#status_bar");
        var c = $('<p class="error">' + d + "<p>").prependTo(b);
        a.set_visible(b);
        setTimeout(function() {
            c.fadeOut(function() {
                c.remove();
                a.set_visible(b)
            })
        }, 8000)
    },
    task_display: function(f) {
        var e = this._tasks[f];
        if (!e) {
            return
        }
        var b = e.files ? e.files.length : 1;
        if (!b) {
            return
        }
        function c(d) {
            if (d && e.percent_val != d) {
                e.epercent.css({
                    width: d + "%"
                });
                e.percent_val = d
            }
        }
        var a = "";
        switch (e.operation) {
        case "move":
            a += "Déplacement";
            break;
        case "rename":
            a += "Renommage";
            break;
        case "copy":
            a += "Copie";
            break;
        case "remove":
            a += "Suppression";
            break;
        case "unpack":
            a += "Décompression";
            break;
        default:
            a += "Opération";
            break
        }
        if ((e.status == "waiting" || e.status == "done") && b > 1) {
            a += " de " + b + " éléments ";
            if (e.status == "waiting") {
                a += " en attente..."
            } else {
                a += " terminé.";
                c(100)
            }
        } else {
            if (e.current_file) {
                a += " de " + e.current_file
            } else {
                if (e.files) {
                    a += " de " + e.files[0].name
                } else {
                    a += " d'élément(s)"
                }
            }
            if (e.status == "waiting") {
                a += " en attente..."
            } else {
                if (e.status == "waiting_password") {
                    a += ", mot de passe requis..."
                } else {
                    if (e.status == "done") {
                        if (e.errcode == "ok") {
                            a += " terminé."
                        } else {
                            a += " terminé avec des erreurs."
                        }
                        c(100)
                    } else {
                        a += " en cours...";
                        if (e.rate > 0) {
                            a += " à " + format_rate(e.rate)
                        }
                        if (e.eta > 0) {
                            a += " (" + format_duration(e.eta) + " restantes)"
                        } else {
                            if (e.percent > 0) {
                                a += " (" + e.percent + " %)"
                            }
                        }
                        c(e.percent)
                    }
                }
            }
        }
        if (a != e.text) {
            e.text = a;
            e.etext.html(a)
        }
    },
    task_update: function(c, b) {
        var a = this._tasks[c];
        if (a) {
            a.status = b.status;
            a.rate = b.rate;
            a.eta = b.eta;
            a.percent = b.percent;
            a.errcode = b.errcode;
            a.current_file = b.current_file;
            if (a.status == "done") {
                if (!a.gc && a.operation != "rename") {
                    if (a.operation == "remove" && b.src_path) {
                        exp.refresh_dir(b.src_path.replace(/[^\/]*\/$/, "") || b.src_path)
                    } else {
                        if (a.operation != "copy") {
                            exp.refresh_dir(b.src_path)
                        }
                    }
                    exp.refresh_dir(b.dst_path)
                }
                if (++a.gc > 2) {
                    this.task_remove(c)
                }
            }
            if (a.status == "waiting_password" && !a.dlg_passwd_show) {
                this.passwd_show(c)
            }
            this.task_display(c)
        }
    },
    task_add: function(g, c, e) {
        var a = $('<p class="text" />');
        var d = $('<div class="percent" />');
        var f = $('<div class="container" />').append(d).append(a);
        var b = this;
        this._tasks[g] = {
            id: g,
            state: "waiting",
            files: e,
            ediv: f,
            etext: a,
            epercent: d,
            text: "",
            percent: 0,
            operation: c,
            gc: 0
        };
        f.appendTo($("#status_bar"));
        this.task_display(g);
        if (!this._trefresh) {
            this.set_visible($("#status_bar"));
            this._trefresh = setTimeout(function() {
                b.tasks_refresh()
            }, 250)
        }
    },
    task_remove: function(b) {
        if (this._tasks[b]) {
            this._tasks[b].ediv.remove();
            var a = $("#status_bar");
            if (!a.children().length) {
                clearTimeout(this._trefresh);
                this._trefresh = null;
                this.set_visible(a)
            }
            this.passwd_hide(b);
            delete this._tasks[b]
        }
    },
    tasks_refresh: function() {
        var a = this;
        $.jsonrpc({
            method: "fs.operation_list",
            success: function(f) {
                for (var e in a._tasks) {
                    a._tasks[e].check = false
                }
                for (var b in f) {
                    var g = f[b];
                    if (a._tasks[g.id]) {
                        a._tasks[g.id].check = true;
                        a.task_update(g.id, g)
                    } else {
                        if (g.status != "done") {
                            a.task_add(g.id, g.operation, undefined);
                            a._tasks[g.id].check = true
                        }
                    }
                }
                for (var c in a._tasks) {
                    if (!a._tasks[c].check) {
                        a.task_remove(c)
                    }
                }
                if (a._trefresh) {
                    a._trefresh = setTimeout(function() {
                        a.tasks_refresh()
                    }, 1000)
                }
            },
            error: function(b) {
                console.error(b);
                $("#status_bar").empty();
                a._tasks = []
            }
        })
    },
    task_abort: function(a) {
        $.jsonrpc({
            method: "fs.abort",
            data: a,
            success: function(b) {
                status_bar.task_remove(b)
            },
            error: function(b, c) {
                console.error("while aborting " + a, b, c)
            }
        })
    },
    passwd_show: function(d) {
        var b = this._tasks[d];
        var a = this;
        var c = {
            url: "fs.cgi",
            data: {
                method: "fs.set_password"
            },
            dataType: "json",
            success: function(e) {
                if (!e.error) {
                    a.passwd_hide(d)
                }
            }
        };
        if (this.dlg_passwd_show) {
            return
        }
        $("#dlg_passwd").dialog({
            resizable: false,
            draggable: true,
            minHeight: 150,
            closeOnEscape: false,
            open: function(e, f) {
                $(".ui-dialog-titlebar-close").hide()
            },
            buttons: {
                Annuler: function() {
                    a.task_abort(d);
                    a.passwd_hide(d)
                },
                Ok: function() {
                    console.log("ajax submit bordel!", $("#form_passwd"));
                    $("#form_passwd").ajaxSubmit(c)
                }
            }
        });
        $("#dlg_passwd").attr("title", b.files ? b.files[0].name : "Mot de passe");
        $("#form_passwd_id").attr("value", b.id);
        $("#form_passwd").ajaxForm(c);
        b.dlg_passwd_show = true;
        this.dlg_passwd_show = true
    },
    passwd_hide: function(b) {
        var a = this._tasks[b];
        if (a.dlg_passwd_show && this.dlg_passwd_show) {
            $("#dlg_passwd").dialog("destroy");
            this.dlg_passwd_show = false
        }
    }
});
var File = Base.extend({
    constructor: function(a, b) {
        this._is_dir = false;
        this.panel = a;
        this.name = b.name;
        this.type = b.type;
        this.e = this.build(b);
        return this
    },
    build: function(c) {
        var d = ejs.esc(c.name);
        var a = $("<li><span>" + d + "</span></li>");
        if (c.type == "dir") {
            a.addClass("ext_folder");
            this._is_dir = true
        } else {
            var b = d.match(/\.([^.]{1,5})$/);
            if (b) {
                this.ext = b[1];
                a.addClass("ext_" + this.ext)
            } else {
                a.addClass("ext")
            }
        }
        a.data("file", this);
        return a
    },
    rename: function() {}
});
var Panel = Base.extend({
    constructor: function(a) {
        this._side = a;
        this._other_side = null;
        this._cur_dir = null;
        this._selected = false;
        this._folders = [];
        this._folder_sel_idx = -1;
        this._files = [];
        this._last_sel_idx = -1;
        this._epanel = $("#" + this._side + "_panel");
        this._efile = $("#" + this._side + "_file");
        this._file_sel = "#" + this._side + "_file li.selected"
    },
    set_other_side: function(a) {
        this._other_side = a
    },
    select: function(b, a) {
        if (this._selected == b) {
            return
        }
        if (b) {
            this._other_side.select(false, true)
        } else {
            $("#" + this._side + "_file li").removeClass("selected");
            this._last_sel_idx = -1
        }
        this._selected = b;
        if (!a) {
            exp.update_toolbar()
        }
    },
    folder_change: function(d) {
        for (var a in this._folders) {
            this._folders[a].e.remove()
        }
        this._folders = [];
        this._folder_sel_idx = -1;
        this._folder_resized = false;
        var c = d.split(/\//);
        for (var b = 0; b < c.length; b++) {
            if (c[b]) {
                this.folder_enter(c[b], true)
            }
        }
        $("#" + this._side + "_folder li :not(:last)").removeClass("last");
        this.filelist_refresh(d)
    },
    folder_enter: function(c, e) {
        var g = $("#" + this._side + "_folder ul");
        var n = this;
        if (!e) {
            var b = this._folders.splice(this._folder_sel_idx + 1, this._folders.length);
            for (var k in b) {
                b[k].e.remove()
            }
            g.children(".last").removeClass("last").css("width", "30px")
        }
        var l = ++this._folder_sel_idx;
        var m = $('<li title="' + c + '" class="last tip">' + c + "</li>");
        m.data("idx", l);
        m.tipTip();
        g.append(m);
        var a = g.outerWidth() - 36 - 4;
        var h = 50;
        var d = $("#" + this._side + "_folder li:not(:first,:last)").length;
        var f = $("#" + this._side + "_folder li:last");
        var j = a * 45 / 100 + 14;
        if (n._folder_resized || h * d + j > a) {
            var i = (h * d + j - a) / 2 + 1;
            if (i < 0) {
                f.css("width", "45%");
                $("#" + this._side + "_folder li:not(:first,:last)").width(30);
                n._folder_resized = false
            } else {
                f.width(j - 14 - i);
                $("#" + this._side + "_folder li:not(:first,:last)").each(function() {
                    $(this).width(30 - (i / d) - 1)
                });
                n._folder_resized = true
            }
        }
        m.click(function() {
            n.folder_select(l)
        });
        this._folders.push({
            name: c,
            e: m
        });
        if (!e) {
            this.filelist_refresh(this._cur_dir + c)
        }
    },
    folder_select: function(a) {
        var d = this._folders[a];
        if (d && a != this._folder_sel_idx) {
            var b = "/";
            for (var c = 0; c < a; c++) {
                b += this._folders[c].name + "/"
            }
            this._cur_dir = b;
            this._folder_sel_idx = a - 1;
            this.folder_enter(d.name)
        }
    },
    filelist_refresh: function(b) {
        var c = Math.random();
        var a = this;
        b = b.replace(/\/*$/, "") + "/";
        this._cur_dir = b;
        this._files = [];
        this._efile.empty();
        this._fslist_id = c;
        this.select(false);
        exp.update_toolbar();
        $.jsonrpc({
            method: "fs.list",
            id: a._fslist_id,
            data: [b,
            {
                with_attr: true
            }],
            success: function(h, j) {
                if (a._fslist_id != c) {
                    return
                }
                for (var g in h) {
                    var f = new File(a, h[g]);
                    a._files.push(f)
                }
                function e(k, d) {
                    if (k.type == "dir" && d.type == "dir") {
                        return k.name > d.name
                    }
                    if (k.type == "dir" && d.type != "dir") {
                        return -1
                    }
                    if (d.type == "dir" && k.type != "dir") {
                        return 1
                    }
                    return k.name > d.name
                }
                a._files.sort(e);
                for (var i in a._files) {
                    a._efile.append(a._files[i].e)
                }
            },
            error: function(d) {
                status_bar.push_error("Impossible de lister les fichiers du répertoire " + b);
                this._cur_dir = null
            }
        })
    },
    contextmenu_show: function(g) {
        var d = [],
            c = [],
            a = false;
        var b = this;
        this._efile.children().each(function(j) {
            var h = $(this).position();
            if (g.y >= h.top && g.y < h.top + $(this).height()) {
                if ($(exp._left._file_sel).length == 0 && $(exp._right._file_sel).length == 0) {
                    $(this).addClass("selected");
                    b.select(true)
                }
                return false
            }
            return true
        });
        var e = $(this._file_sel);
        if (e.length > 0) {
            d.push(".cut,.copy,.delete");
            $(e).each(function() {
                var h = $(this).data("file").ext;
                if (h == "zip" || h == "rar" || h == "tar" || h == "tar.gz") {
                    a = true
                }
            });
            if (a) {
                d.push(".unpack")
            } else {
                c.push(".unpack")
            }
            if (e.length == 1) {
                d.push(".rename");
                var f = $(e).first().data("file")._is_dir;
                if (!f) {
                    d.push(".get")
                } else {
                    c.push(".get")
                }
            } else {
                c.push(".rename,.get")
            }
        } else {
            c.push(".cut,.copy,.delete,.unpack,.rename,.get")
        }
        if (exp._cc_files.length > 0 && exp._left._cur_dir != exp._right._cur_dir) {
            d.push(".paste")
        } else {
            c.push(".paste")
        }
        $("#file_context_menu").enableContextMenuItems(d.join(","));
        $("#file_context_menu").disableContextMenuItems(c.join(","))
    },
    contextmenu_click: function(g, d) {
        var c = $(d).children();
        var a = c.data("panel");
        switch (g) {
        case "cut":
        case "copy":
            exp.cut(a._cur_dir, $(a._file_sel), g == "copy");
            break;
        case "paste":
            exp.paste(a);
            break;
        case "rename":
            d = c.find("li.selected:first");
            var e = $(d).data("file").name;
            d.html('<input id="inp_rename" type="text" value="' + e + '">');
            var f = function(i) {
                    var h = $(this).val();
                    if (!i && h && e != h) {
                        exp.file_rename(a._cur_dir, d, h);
                        $(d).data("file").name = h
                    } else {
                        h = e
                    }
                    $(d).html("<span>" + h + "</span>")
                };
            $("#inp_rename").focus().blur(function() {
                f.call(this, true)
            }).keypress(function(h) {
                switch (h.keyCode) {
                case 13:
                    f.call(this, false);
                    break;
                case 27:
                    f.call(this, true);
                    break
                }
            });
            break;
        case "get":
            d = c.find("li.selected:first");
            var b = $(d).data("file").name;
            exp.file_download(a._cur_dir, b);
            break;
        case "delete":
            exp.file_remove(a._cur_dir, $(a._file_sel));
            break;
        case "unpack":
            exp.archive_unpack(a._cur_dir, $(a._file_sel));
            break
        }
    },
    build: function() {
        var a = this;
        this._efile.click(function(f) {
            var d = $(f.target).closest("li");
            if (!d.length) {
                return
            }
            if (f.shiftKey && a._last_sel_idx >= 0) {
                var g = a._last_sel_idx;
                var c = d.index();
                if (g > c) {
                    g = c;
                    c = a._last_sel_idx
                }
                $("#" + a._side + "_file li").slice(g, c + 1).addClass("selected");
                return
            } else {
                a._last_sel_idx = d.index()
            }
            var b = $(a._file_sel).length > 1;
            if (d.is(".selected")) {
                if (!f.ctrlKey) {
                    $(a._file_sel).removeClass("selected");
                    if (b) {
                        d.addClass("selected")
                    }
                } else {
                    d.removeClass("selected")
                }
            } else {
                if (!f.ctrlKey) {
                    $(a._file_sel).removeClass("selected")
                }
                d.addClass("selected")
            }
            a.select($(a._file_sel).length > 0)
        });
        this._efile.data("panel", this);
        this._efile.dblclick(function(d) {
            var b = $(d.target).closest("li");
            if (!b.length) {
                return
            }
            var c = b.data("file");
            if (c._is_dir) {
                a.folder_enter(c.name)
            }
        });
        this._efile.parent().contextMenu({
            menu: "file_context_menu",
            click: function(c, b, d) {
                a.contextmenu_click(c, b)
            },
            show: function(b) {
                a.contextmenu_show(b)
            }
        });
        $("#link_tool_" + this._side + "_mv").click(function() {
            exp.file_move(a._cur_dir, $(a._file_sel), a._other_side, false);
            return false
        });
        $("#link_tool_" + this._side + "_cp").click(function() {
            exp.file_move(a._cur_dir, $(a._file_sel), a._other_side, true);
            return false
        });
        $("#" + this._side + "_selall").click(function() {
            $("#" + a._side + "_file li").addClass("selected");
            a.select($(a._file_sel).length > 0);
            return false
        });
        $("#" + this._side + "_unselall").click(function() {
            $("#" + a._side + "_file li").removeClass("selected");
            a.select(false);
            return false
        });
        $("#" + this._side + "_home").click(function() {
            a.folder_change("/")
        });
        this.filelist_refresh("/")
    }
});
var Explorer = Base.extend({
    constructor: function() {
        var a = this;
        exp = a;
        this._left = new Panel("left");
        this._right = new Panel("right");
        this._left.set_other_side(this._right);
        this._right.set_other_side(this._left);
        this._left.build();
        this._right.build();
        this._cc_files = [];
        $(".tip").tipTip();
        $("#link_tool_del").click(function() {
            exp.file_remove(a._left._cur_dir, $("#left_file li.selected"));
            exp.file_remove(a._right._cur_dir, $("#right_file li.selected"))
        });
        $(document).keypress(function(d) {
            function b() {
                if ($(a._left._file_sel).length == 1) {
                    return a._left
                } else {
                    if ($(a._right._file_sel).length == 1) {
                        return a._right
                    }
                }
                return undefined
            }
            if (d.keyCode == 46) {
                exp.file_remove(a._left._cur_dir, $("#left_file li.selected"));
                exp.file_remove(a._right._cur_dir, $("#right_file li.selected"))
            }
            if (d.keyCode == 113) {
                var c = b();
                if (c) {
                    c.contextmenu_click("rename", c._efile.parent())
                }
            }
        });
        return this
    },
    update_toolbar: function() {
        var h = false,
            g = false,
            b = false;
        var c = $("#link_tool_left_mv img");
        var j = $("#link_tool_left_cp img");
        var i = $("#link_tool_del img");
        var f = $("#link_tool_right_mv img");
        var d = $("#link_tool_right_cp img");
        var e = this._left,
            a = this._right;
        if (e._cur_dir != a._cur_dir) {
            if (e._selected) {
                b = h = true
            }
            if (a._selected) {
                b = g = true
            }
        } else {
            if (e._selected || a._selected) {
                b = true
            }
        }
        i.attr({
            src: "im/explorer/del" + (b ? "" : "_inact") + ".png"
        });
        c.attr({
            src: "im/explorer/mv_r" + (h ? "" : "_inact") + ".png"
        });
        j.attr({
            src: "im/explorer/cp_r" + (h ? "" : "_inact") + ".png"
        });
        f.attr({
            src: "im/explorer/mv_l" + (g ? "" : "_inact") + ".png"
        });
        d.attr({
            src: "im/explorer/cp_l" + (g ? "" : "_inact") + ".png"
        })
    },
    refresh_dir: function(a) {
        if (!a) {
            return
        }
        a = a.replace(/\/*$/, "") + "/";

        function b(c, e) {
            var d = e.substring(0, a.length);
            console.log("refresh ", e, d, a);
            if (d == a) {
                c.filelist_refresh(e)
            }
        }
        if (this._left._cur_dir) {
            b(this._left, this._left._cur_dir)
        }
        if (this._right._cur_dir) {
            b(this._right, this._right._cur_dir)
        }
    },
    get_file_list: function(b) {
        if (b.each) {
            var a = [];
            b.each(function() {
                a.push($(this).data("file"))
            });
            return a
        } else {
            if (!$.isArray(b)) {
                return [b]
            } else {
                return b
            }
        }
    },
    cut: function(a, b, c) {
        this._cc_copy = c;
        this._cc_dir = a;
        this._cc_files = this.get_file_list(b)
    },
    paste: function(a) {
        if (this._cc_files.length > 0) {
            exp.file_move(this._cc_dir, this._cc_files, a, this._cc_copy);
            this._cc_files = []
        }
    },
    file_remove: function(c, e) {
        if (!c || !e.length) {
            return
        }
        var b = this.get_file_list(e);
        var d = [];
        for (var a in b) {
            d.push(c + b[a].name)
        }
        $.jsonrpc({
            url: "fs.cgi",
            method: "fs.remove",
            data: [d],
            success: function(f) {
                status_bar.task_add(f, "remove", b)
            },
            error: function(f, g) {
                status_bar.push_error("Échec de la suppression: " + g)
            }
        })
    },
    file_rename: function(b, d, c) {
        var a = this.get_file_list(d);
        if (a.length != 1 || typeof c != "string" || !c || typeof b != "string" || !b) {
            return
        }
        $.jsonrpc({
            method: "fs.move",
            data: [b + a[0].name, b + c],
            success: function(e) {
                status_bar.task_add(e, "rename", a)
            },
            error: function(e, f) {
                status_bar.push_error("Échec du renommage: " + f)
            }
        })
    },
    file_move: function(d, e, f, b) {
        var a = b ? "fs.copy" : "fs.move";
        var c = f._cur_dir;
        if (!e.length || !d || !c || d == c) {
            return
        }
        var g = this.get_file_list(e);
        var i = [];
        for (var h in g) {
            i.push(d + g[h].name)
        }
        $.jsonrpc({
            url: "fs.cgi",
            method: a,
            data: [i, c],
            success: function(j) {
                status_bar.task_add(j, b ? "copy" : "move", g)
            },
            error: function(j, k) {
                status_bar.push_error("Échec " + (b ? "de la copie: " : "du déplacement: ") + k)
            }
        })
    },
    file_download: function(b, a) {
        var c = $('<form method="post" action="/get.php">  <input type="hidden" name="filename" /></form>');
        $("#fluid").append(c);
        $("input[name=filename]").attr("value", b + a);
        c.submit().remove()
    },
    archive_unpack: function(c, d) {
        if (!d.length || !c) {
            return
        }
        var g = this.get_file_list(d);
        var j = [],
            f = [];
        for (var h in g) {
            var a = g[h].name;
            var b = a.match(/^(.*?)([\.-](part|)[0-9]+|)\.rar$/);
            if (b && b[1]) {
                var i = false;
                for (var e in f) {
                    if (f[e] == b[1]) {
                        i = true
                    }
                }
                if (i) {
                    g.splice(h, 1);
                    continue
                }
                f.push(b[1])
            }
            j.push({
                method: "fs.unpack",
                data: c + a,
                success: function(k) {
                    status_bar.task_add(k, "unpack", g)
                },
                error: function(k, l) {
                    status_bar.push_error("Échec de la décompression :" + l)
                }
            })
        }
        $.jsonrpc({
            url: "fs.cgi",
            batch: j
        })
    }
});
$(document).ready(function() {
    status_bar = new SBar();
    exp = new Explorer()
});
