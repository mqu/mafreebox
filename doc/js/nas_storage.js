var dlg_format_progress;
var dlg_confirm;

function report_format_error() {
    ejs.get("tpl/nas_storage_format_error.ejs", {}, function(a) {
        a.dialog({
            resizable: false,
            modal: true,
            height: 190,
            width: 300,
            buttons: {
                Continuer: function() {
                    $(this).dialog("close")
                }
            }
        })
    })
}
function report_format_success() {
    ejs.get("tpl/nas_storage_format_success.ejs", {}, function(a) {
        a.dialog({
            resizable: false,
            modal: true,
            height: 190,
            width: 300,
            buttons: {
                Continuer: function() {
                    $(this).dialog("close")
                }
            }
        })
    })
}
function format_progress() {
    $.jsonrpc({
        method: "storage.disk_get",
        data: 0,
        success: function(a) {
            console.log("success... ", a);
            if (a.state == "formating") {
                if (a.state_data.format.max_steps) {
                    $("#div_step").show();
                    $("#div_step").html("Etape: " + a.state_data.format.done_steps + "/" + a.state_data.format.max_steps);
                    $("#format_progressbar").show();
                    $("#format_progressbar").progressbar("option", "value", a.state_data.format.done_steps * 100 / a.state_data.format.max_steps)
                }
                if (a.state_data.format.percent) {
                    $("#div_substep").html("Progression de l'étape: " + a.state_data.format.percent + "%");
                    $("#div_substep").show();
                    $("#format_subprogressbar").show();
                    $("#format_subprogressbar").progressbar("option", "value", a.state_data.format.percent)
                } else {
                    $("#div_substep").hide();
                    $("#format_subprogressbar").hide()
                }
                setTimeout(format_progress, 1000)
            } else {
                if (a.state == "error") {
                    console.log("erreur lors du formatage");
                    dlg_format_progress.remove();
                    dlg_format_progress = undefined;
                    report_format_error()
                } else {
                    console.log("formatage termine");
                    dlg_format_progress.remove();
                    dlg_format_progress = undefined;
                    report_format_success()
                }
            }
        }
    })
}
var partition_fsck_ctx = {};

function partition_fsck_result(a) {
    ejs.get("tpl/nas_storage_partition_fsck_result.ejs", {
        result: a
    }, function(b) {
        $("#fluid").append(b);
        b.dialog({
            resizable: false,
            modal: true,
            width: 640,
            height: 480,
            buttons: {
                Continuer: function() {
                    b.remove()
                }
            }
        })
    })
}
function partition_fsck_progress_update(a) {
    $.jsonrpc({
        url: "storage.cgi",
        method: "storage.partition_get",
        data: [partition_fsck_ctx.partition_id],
        success: function(b) {
            switch (b.fsck_result) {
            case "running":
                setTimeout(function() {
                    partition_fsck_progress_update(a)
                }, 1000);
                if (b.state_data.checking) {
                    $("#partition_fsck_progressbar").progressbar("option", "value", b.state_data.checking.percent)
                }
                break;
            default:
                a.remove();
                partition_fsck_result(b.fsck_result);
                break
            }
        }
    })
}
function partition_fsck_progress() {
    ejs.get("tpl/nas_storage_partition_fsck_progress.ejs", {}, function(a) {
        $("#fluid").append(a);
        $("#partition_fsck_progressbar").progressbar();
        a.dialog({
            resizable: false,
            modal: true,
            width: 640,
            height: 480
        });
        setTimeout(function() {
            partition_fsck_progress_update(a)
        }, 1000)
    })
}
function partition_fsck_error() {
    ejs.get("tpl/nas_storage_partition_fsck_error.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            width: 640,
            height: 480,
            modal: true,
            buttons: {
                Continuer: function() {
                    a.remove()
                }
            }
        })
    })
}
function partition_fsck_do() {
    $.jsonrpc({
        url: "storage.cgi",
        method: "storage.partition_fsck",
        data: [partition_fsck_ctx.partition_id, partition_fsck_ctx.mode],
        success: function() {
            partition_fsck_progress()
        },
        error: function() {
            partition_fsck_error()
        }
    })
}
function partition_fsck_config() {
    ejs.get("tpl/nas_storage_partition_fsck_config.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            width: 640,
            height: 480,
            buttons: {
                Suivant: function() {
                    partition_fsck_ctx.mode = $("#fsck_mode_select").attr("value");
                    a.remove();
                    partition_fsck_do()
                },
                Annuler: function() {
                    a.remove()
                }
            }
        })
    })
}
function partition_fsck_unsupported() {
    ejs.get("tpl/nas_storage_partition_fsck_unsupported.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            width: 640,
            height: 480,
            buttons: {
                Annuler: function() {
                    a.remove()
                }
            }
        })
    })
}
var disk_format_ctx = {};

function update_simple_config(c) {
    var a = "Système de fichier : ";
    var b = "Table de partition : ";
    switch (c) {
    case "usage_windows":
        disk_format_ctx.fstype = "ntfs";
        disk_format_ctx.ptype = "msdos";
        break;
    default:
    case "usage_linux":
        disk_format_ctx.fstype = "ext4";
        disk_format_ctx.ptype = "gpt";
        break;
    case "usage_mac":
        disk_format_ctx.fstype = "hfsplus";
        disk_format_ctx.ptype = "gpt";
        break;
    case "usage_other":
        disk_format_ctx.fstype = "manual";
        disk_format_ctx.ptype = "manual";
        break
    }
    switch (disk_format_ctx.fstype) {
    case "ext4":
        a += "EXT4";
        break;
    case "ntfs":
        a += "NTFS";
        break;
    case "vfat":
        a += "FAT 32";
        break;
    case "hfsplus":
        a += "HFS Plus";
        break;
    default:
        a += "Configuration manuelle";
        break
    }
    $("#info_fstype").html(a);
    switch (disk_format_ctx.ptype) {
    case "gpt":
        b += "GUID";
        break;
    default:
        b += "Configuration manuelle";
        break;
    case "msdos":
        b += "MBR";
        break
    }
    $("#info_ptype").html(b)
}
function disk_format_wizard_simple() {
    ejs.get("tpl/nas_storage_disk_format_config_simple.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            buttons: {
                Suivant: function() {
                    disk_format_ctx.label = $("#disk_label").val();
                    a.remove();
                    if (disk_format_ctx.fstype == "manual" || disk_format_ctx.ptype == "manual") {
                        disk_format_wizard_advanced()
                    } else {
                        disk_format_wizard_confirm()
                    }
                },
                Annuler: function() {
                    a.remove()
                }
            },
            width: 640,
            height: 480
        });
        update_simple_config($("#disk_intended_usage").val());
        $("#disk_intended_usage").change(function() {
            update_simple_config($("#disk_intended_usage").val())
        })
    })
}
function disk_format_wizard_advanced() {
    ejs.get("tpl/nas_storage_disk_format_config.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            buttons: {
                Suivant: function() {
                    disk_format_ctx.label = $("#disk_label").val();
                    disk_format_ctx.fstype = $("#disk_fstype").val();
                    disk_format_ctx.ptype = $("#disk_ptype").val();
                    a.remove();
                    disk_format_wizard_confirm()
                },
                "Précédent": function() {
                    disk_format_ctx.label = $("#disk_label").val();
                    disk_format_ctx.fstype = $("#disk_fstype").attr("value");
                    disk_format_ctx.ptype = $("#disk_ptype").attr("value");
                    a.remove();
                    disk_format_wizard_simple()
                },
                Annuler: function() {
                    a.remove()
                }
            },
            width: 640,
            height: 480
        })
    })
}
function disk_format_wizard_progress_update(a) {
    $.jsonrpc({
        method: "storage.disk_get",
        data: disk_format_ctx.disk_id,
        success: function(b) {
            if (b.state == "formating") {
                if (b.state_data.format && b.state_data.format.max_steps) {
                    $("#div_step").show();
                    $("#div_step").html("Etape: " + b.state_data.format.done_steps + "/" + b.state_data.format.max_steps);
                    $("#format_progressbar").progressbar("option", "value", b.state_data.format.done_steps * 100 / b.state_data.format.max_steps)
                }
                if (b.state_data.format && b.state_data.format.percent > 0) {
                    $("#div_substep").html("Progression de l'étape: " + b.state_data.format.percent + "%");
                    $("#div_substep").show();
                    $("#format_subprogressbar").show();
                    $("#format_subprogressbar").progressbar("option", "value", b.state_data.format.percent)
                } else {
                    $("#format_subprogressbar").hide();
                    $("#div_substep").hide()
                }
                setTimeout(function() {
                    disk_format_wizard_progress_update(a)
                }, 1000)
            } else {
                if (b.state == "error") {
                    a.remove();
                    disk_format_wizard_report_error()
                } else {
                    a.remove();
                    disk_format_wizard_report_success()
                }
            }
        }
    })
}
function disk_format_wizard_report_success() {
    ejs.get("tpl/nas_storage_disk_format_success.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            buttons: {
                Continuer: function() {
                    a.remove()
                }
            },
            width: 640,
            height: 480
        })
    })
}
function disk_format_wizard_progress() {
    ejs.get("tpl/nas_storage_disk_format_progress.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            width: 640,
            height: 480
        });
        $("#format_progressbar").progressbar();
        $("#format_subprogressbar").progressbar();
        setTimeout(function() {
            disk_format_wizard_progress_update(a)
        }, 1000)
    })
}
function disk_format_wizard_report_error() {
    ejs.get("tpl/nas_storage_disk_format_error.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            width: 640,
            height: 480,
            buttons: {
                Continuer: function() {
                    a.remove()
                }
            }
        })
    })
}
function disk_format_wizard_do() {
    $.jsonrpc({
        url: "storage.cgi",
        method: "storage.format_simple",
        data: [disk_format_ctx.disk_id, disk_format_ctx.fstype, disk_format_ctx.ptype, disk_format_ctx.label],
        success: function() {
            disk_format_wizard_progress()
        },
        error: function() {
            disk_format_wizard_report_error()
        }
    })
}
function disk_format_wizard_confirm() {
    ejs.get("tpl/nas_storage_disk_format_confirm.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            buttons: {
                Formater: function() {
                    a.remove();
                    disk_format_wizard_do()
                },
                "Précédent": function() {
                    a.remove();
                    disk_format_wizard_simple()
                },
                Annuler: function() {
                    a.remove()
                }
            },
            width: 640,
            height: 480
        })
    })
}
var disk_advanced_informations_ctx = {};

function disk_advanced_informations_show() {
    ejs.get("tpl/nas_storage_disk_advanced_informations.ejs", {}, function(a) {
        $("#fluid").append(a);
        a.dialog({
            resizable: false,
            modal: true,
            width: 640,
            height: 480,
            buttons: {
                Retour: function() {
                    clearInterval(disk_advanced_informations_ctx.timer);
                    a.remove()
                }
            }
        })
    });
    disk_advanced_informations_ctx.timer = setInterval(function() {
        $.jsonrpc({
            url: "storage.cgi",
            method: "storage.disk_advanced_informations_get",
            data: disk_advanced_informations_ctx.disk.disk_id,
            success: function(a) {
                var b = "";
                if (a.idle) {
                    b = "Inactif / "
                } else {
                    b = "Actif / "
                }
                if (a.spinning) {
                    b += "Rotation en cours"
                } else {
                    b += "Disque arrêté"
                }
                $("#advanced_state_entry").html("État: <b>" + b + "</b>");
                if (a.idle) {
                    $("#advanced_idle_duration_entry").show();
                    $("#advanced_active_duration_entry").hide();
                    $("#advanced_idle_duration_entry").html("Inactif depuis: <b>" + format_duration(a.idle_duration) + "</b>")
                } else {
                    $("#advanced_active_duration_entry").show();
                    $("#advanced_idle_duration_entry").hide();
                    $("#advanced_active_duration_entry").html("Actif depuis: <b>" + format_duration(a.active_duration) + "</b>")
                }
                if (a.temperature_valid) {
                    $("#advanced_temperature").html("Température: <b>" + a.temperature + "°C</b>")
                } else {
                    $("#advanced_temperature").html("Température: <b>non supportée</b>")
                }
                if (a.spinning && a.idle) {
                    var c = (10 * 60) - a.idle_duration;
                    if (a.idle_duration < 0) {
                        $("#advanced_time_before_spindown").hide()
                    } else {
                        $("#advanced_time_before_spindown").show();
                        $("#advanced_time_before_spindown").html("Temps avant arrêt: <b>" + format_duration(c) + "</b>")
                    }
                } else {
                    $("#advanced_time_before_spindown").hide()
                }
            }
        })
    }, 1000)
}
$(document).ready(function() {
    $(".lnk_internal_format").live("click", function() {
        if (dlg_confirm) {
            dlg_confirm.remove()
        }
        ejs.get("tpl/nas_storage_format_confirm.ejs", {}, function(a) {
            $("#fluid").append(a);
            a.dialog({
                resizable: false,
                modal: true,
                buttons: {
                    Annuler: function() {
                        dlg_confirm.remove()
                    },
                    Formater: function() {
                        dlg_confirm.remove();
                        if (dlg_format_progress) {
                            dlg_format_progress.remove()
                        }
                        $.jsonrpc({
                            method: "storage.disk_format_internal",
                            success: function() {
                                ejs.get("tpl/nas_storage_format_progress.ejs", {}, function(b) {
                                    $("#fluid").append(b);
                                    b.dialog({
                                        resizable: false,
                                        modal: true,
                                        height: 190,
                                        width: 300,
                                    });
                                    dlg_format_progress = b;
                                    setTimeout(format_progress, 1000);
                                    $("#format_progressbar").progressbar();
                                    $("#format_subprogressbar").progressbar()
                                })
                            }
                        })
                    },
                },
            });
            dlg_confirm = a
        })
    });
    $(".lnk_disk_disable").live("click", function(a) {
        var b = a.target;
        console.log(b);
        $.jsonrpc({
            method: "storage.disk_disable",
            data: $(b).attr("disk_id"),
            success: function() {
                console.log("disque démonté!")
            }
        })
    });
    $(".lnk_disk_format").live("click", function(a) {
        var b = a.target;
        disk_format_ctx.disk_id = $(b).attr("disk_id");
        disk_format_ctx.label = "Disque " + disk_format_ctx.disk_id / 1000;
        $.jsonrpc({
            url: "storage.cgi",
            method: "storage.disk_get",
            data: [disk_format_ctx.disk_id],
            success: function(c) {
                disk_format_ctx.disk = c;
                disk_format_wizard_simple()
            }
        })
    });
    $(".lnk_partition_fsck").live("click", function(a) {
        var b = a.target;
        partition_fsck_ctx.partition_id = $(b).attr("partition_id");
        $.jsonrpc({
            url: "storage.cgi",
            method: "storage.partition_get",
            data: [partition_fsck_ctx.partition_id],
            success: function(c) {
                partition_fsck_ctx.partition = c;
                if (c.fstype == "empty" || c.fstype == "ntfs") {
                    partition_fsck_unsupported()
                } else {
                    partition_fsck_config()
                }
            }
        })
    });
    $(".lnk_partition_enable").live("click", function(b) {
        var c = b.target;
        var a = $(c).attr("partition_id");
        $.jsonrpc({
            url: "storage.cgi",
            method: "storage.mount",
            data: a
        })
    });
    $(".lnk_partition_disable").live("click", function(b) {
        var c = b.target;
        var a = $(c).attr("partition_id");
        $.jsonrpc({
            url: "storage.cgi",
            method: "storage.umount",
            data: a
        })
    });
    $("#disk_list").dynamiclist({
        jsonrpc: {
            method: "storage.list",
        },
        ejs: {
            url: "tpl/nas_storage_disk.ejs",
            data: function(a) {
                return {
                    d: a
                }
            },
        },
        interval: 1000,
        key: "disk_id",
        jsonfield: function(b) {
            return b
        },
        filter: function(a) {
            return true
        },
        ejs_update_if_present: true
    });
    $(".lnk_advanced_informations").live("click", function(a) {
        $.jsonrpc({
            url: "storage.cgi",
            method: "storage.disk_get",
            data: $(a.target).attr("disk_id"),
            success: function(b) {
                disk_advanced_informations_ctx.disk = b;
                disk_advanced_informations_show()
            }
        })
    })
});
