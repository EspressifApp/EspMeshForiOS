define(["vue", "MINT", "Util", "txt!../../pages/debug.html", "./debugInfo"],
    function(v, MINT, Util, debug, debugInfo) {

        var Debug = v.extend({

            template: debug,

            data: function(){
                return {
                    flag: false,
                    deviceList: [],
                    debugList: [],
                    groupList: [],
                    chartList: [],
                    myChart: [],
                    debugInfo: "",
                    rootData: [],
                    titleList: [],
                    selected: "",
                    temporaryAddList: [],
                    temporaryAddMacs: [],
                    temporaryDelList: [],
                }
            },
            watch: {
                selected: function (val, oldVal) {
                    var self = this;
                    if (self.flag && !Util._isEmpty(self.myChart) && !Util._isEmpty(self.selected) ) {
                        if (self.myChart.length > 0) {
                            self.chartList = [];
                            self.disposeChart();
                        }
                        self.getChartData();
                    }
                }
            },
            methods:{
                show: function () {
                    var self = this;
                    self.initHtml();
                    self.flag = true;
                },
                initHtml: function() {
                    var self = this;
                    self.debugList = [];
                    self.deviceList = self.$store.state.deviceList;
                    self.groupList = self.$store.state.groupList;
                    self.titleList = [];
                    self.temporaryAddList = [];
                    self.temporaryAddMacs = [];
                    self.temporaryDelList = [];
                    self.selected = "";
                    self.hideThis();
                    self.chartList = [];
                    self.debugInfo = "";
                    if (self.myChart.length > 0) {
                        self.disposeChart();
                    }
                    MINT.Indicator.open();
                    window.onGetMesh = this.onGetMesh;
                    setTimeout(function() {
                        self.getData();
                        window.onDeviceFound = self.onDeviceFound;
                        window.onDeviceLost = self.onDeviceLost;
                        window.debugResult = self.debugResult;
                    }, 1000);
                },
                disposeChart: function() {
                    var self = this;
                    $.each(self.myChart, function(i, item) {
                        item.chart.dispose();
                    })
                    self.myChart = [];
                },
                refresh: function() {
                    this.initHtml();
                },
                hide: function () {
                    this.flag = false;
                    this.rootData = [];
                    if (this.myChart.length > 0) {
                        this.disposeChart();
                    }
                    window.debugResult = "";
                    MINT.Indicator.close();
                    this.$emit("debugShow");
                },
                getData: function() {
                    var self = this, macs = [], dataJson = {};
                    $.each(self.deviceList, function(i, item) {
                        macs.push(item.mac);
                    })
                    setTimeout(function() {
                        self.hideThis();
                    })
                    var data = '{"' + MESH_MAC + '": ' + JSON.stringify(macs) +
                        ',"'+DEVICE_IP+'": "'+self.$store.state.deviceIp+'","' + MESH_REQUEST +
                        '": "' + GET_MESH + '","callback": "debugResult", "tag": "debugResult"}';
                    espmesh.requestDevicesMulticast(data);

                },
                getMesh: function(macList) {
                    var self = this, macs = [], dataJson = {};
                    $.each(self.debugList, function(i, item) {
                        macs.push(item.mac);
                    })
                    setTimeout(function() {
                        self.hideThis();
                    })
                    var data = '{"' + MESH_MAC + '": ' + JSON.stringify(macList) +
                        ',"'+DEVICE_IP+'": "'+self.$store.state.deviceIp+'","' + MESH_REQUEST + '": "' +
                        GET_MESH + '", "callback": "onGetMesh", "tag": {"macs": '+JSON.stringify(macs)+'}}';
                    espmesh.requestDevicesMulticast(data);

                },
                getInitData: function() {
                    var self = this, layer = 0, rootItem = [],list = [];
                    $.each(self.debugList, function(i, item) {
                        if (item.layer > layer) {
                            layer = item.layer;
                        }
                    });
                    for(var i = layer; i > 0; i--) {
                        var parentItem = [];
                        $.each(self.debugList, function(k, item){
                            var chids = [];
                            if (item.layer == i) {
                                $.each(self.debugList, function(l, itemSub) {
                                    if (itemSub.parent_mac == item.mac) {
                                        var flagRes = true;
                                        $.each(list, function(n, itemThr){
                                            if (itemThr.mac == itemSub.mac) {
                                                chids.push(itemThr);
                                                flagRes = false;
                                                return false;
                                            }
                                        });
                                        if (flagRes) {
                                            chids.push({id: itemSub.mac, meshId: itemSub.id, name: self.getName(itemSub.mac),
                                                label: {color: self.getColor(itemSub.mac)}, mac: itemSub.mac, children: []})
                                        }

                                    }
                                })
                                parentItem.push({id: item.mac, meshId: item.id, name: self.getName(item.mac),
                                    label: {color: self.getColor(item.mac)}, mac: item.mac, children: chids});
                            }
                        });

                        if (i == 1) {
                            rootItem = parentItem;
                        } else {
                            list = parentItem;
                        }
                    }
                    $.each(rootItem, function(i, item) {
                        if (self.titleList.indexOf(item.meshId) == -1) {
                            self.titleList.push(item.meshId);
                        }
                    })
                    self.rootData = rootItem;
                    if (self.titleList.length > 0 && Util._isEmpty(self.selected)) {
                        self.selected = self.titleList[0];
                    }
                },
                getChartData: function() {
                    var self = this, objList = [];
                    $.each(self.rootData, function(i, item) {
                        if (item.meshId == self.selected) {
                            objList.push(item);
                        }
                    })
                    self.chartList = objList;
                },
                setTitle: function(id) {
                    var self = this, name = id;
                    $.each(self.groupList, function(i, item) {
                        if (item.id == parseInt(id, 16)) {
                            name = item.name;
                            return false;
                        }
                    });
                    return name;
                },
                getName: function(mac) {
                    var self = this, name = "";
                    $.each(self.deviceList, function(i, item){
                        if (item.mac == mac) {
                            if (!Util._isEmpty(item.position)) {
                                name = item.position;
                            } else {
                                name = item.name;
                            }
                            return false;
                        }
                    });
                    return name;
                },
                getColor: function(mac) {
                    return "#666";
                },
                debugChart: function(data, id) {
                    var self = this;
                    setTimeout(function() {
                        if (self.myChart.length > 0) {
                            self.changChart(data, id)
                        } else {
                            self.initChart(data, id);
                        }
                    }, 500)
                },
                initChart: function (data, id) {
                    var self = this;
                    console.log(JSON.stringify(data));
                    console.log(id);
                    var chart = echarts.init(document.getElementById(id));
                    window.addEventListener('resize',function(){
                        chart.resize();
                    });
                    var option = {
                        tooltip: {
                            trigger: 'item',
                            formatter: function(data){

                            }
                        },
                        series: [
                            {
                                type: 'tree',
                                initialTreeDepth: 15,
                                data: [data],

                                top: '18%',
                                left: '8%',
                                bottom: '5%',
                                right: '2%',

                                symbolSize: 18,
                                // orient: 'vertical',
                                itemStyle: {
                                    normal: {
                                        borderColor: "#44B2F8"
                                    }
                                },
                                label: {
                                    normal: {
                                        position: 'left',
                                        // rotate: -90,
                                        verticalAlign: 'middle',
                                        align: 'right',
                                        fontSize: 11,
                                    }
                                },
                                lineStyle: {
                                    normal: {

                                    }
                                },
                                leaves: {
                                    label: {
                                        normal: {
                                            position: 'bottom',
                                            // rotate: -90,
                                            verticalAlign: 'middle',
                                            align: 'left'
                                        }
                                    }
                                },


                            }
                        ]
                    }
                    chart.setOption(option);
                    var timeOutEvent = 0;
                    chart.on("mousedown", function(params) {
                        timeOutEvent = setTimeout(function(){
                            self.getDebugInfo(params.data.id);
                            setTimeout(function() {
                                self.showDebugInfo();
                            })
                        },500);
                    })
                    chart.on("mousemove", function(params) {
                        clearTimeout(timeOutEvent);//清除定时器
                        timeOutEvent = 0;
                    })
                    chart.on("mouseup", function(params) {
                        clearTimeout(timeOutEvent);//清除定时器
                        timeOutEvent = 0;
                    });
                    self.myChart.push({id: id, chart: chart});
                },
                showDebugInfo: function () {
                    this.$refs.debugInfo.show();
                },
                getDebugInfo: function(mac) {
                    var self = this;
                    $.each(self.debugList, function(i, item) {
                        if (item.mac == mac) {
                            self.debugInfo = item;
                            return false;
                        }
                    })
                },
                hideThis: function () {
                    window.onBackPressed = this.hide;
                },
                setPair: function(device) {
                    var self = this, position = "", pairMacs = [],
                        pairs = self.$store.state.siteList;
                    $.each(pairs, function(i, item) {
                        pairMacs.push(item.mac);
                    });
                    if (!Util._isEmpty(device.position)) {
                        position = device.position.split("-");
                        espmesh.saveHWDevices(JSON.stringify([{"mac": device.mac, "code": position[2],
                            "floor": position[0], "area":  position[1]}]));

                    } else {
                        $.each(pairs, function(i, item) {
                            if (item.mac == device.mac) {
                                device.position = item.floor + "-" + item.area + "-" + item.code;
                                var data = '{"' + MESH_MAC + '": "' + device.mac +
                                    '","'+DEVICE_IP+'": "'+self.$store.state.deviceIp+'","'+NO_RESPONSE+'": true,"' + MESH_REQUEST + '": "' + SET_POSITION + '",' +
                                    '"position":"' + device.position + '"}';
                                espmesh.requestDevice(data);
                                return  false;
                            }
                        });
                    }
                    espmesh.loadHWDevices();
                    return device;
                },
                getPosition: function(position) {
                    return Util.getPosition(position);
                },
                getPOrN: function(position, name) {
                    var self = this, obj = name,
                        objP = self.getPosition(position);
                    if (!Util._isEmpty(objP)) {
                        obj = objP;
                    }
                    return obj;
                },
                changChart: function(data, id) {
                    var self = this;
                    $.each(self.myChart, function(i, item) {
                        if (item.id == id) {
                            item.chart.setOption({
                                series:[
                                    {
                                        data: [data]
                                    }
                                ]
                            })
                            return false;
                        }
                    })
                },
                onGetMesh: function(res) {
                    var self = this;
                    console.log(res)
                    if (!Util._isEmpty(res)) {
                        res = JSON.parse(res);
                        var macs = res.tag.macs,
                            list = res.result;
                        if (list.length > 0) {
                            $.each(list, function(i, item) {
                                if (macs.indexOf(item.mac) == -1) {
                                    console.log('走了')
                                    self.debugList.push(item);
                                }
                            })
                            console.log(self.debugList.length);
                            setTimeout(function() {
                                self.getInitData();
                                self.getChartData();
                            }, 500)

                        }
                    }
                },
                onDeviceFound: function (device) {
                    var self = this;
                    if (Util._isEmpty(self.deviceList)) {
                        self.deviceList = [];
                    }
                    if (!Util._isEmpty(device)) {
                        device = JSON.parse(device);
                        var isExist = true;
                        if (self.temporaryAddList.length == 0) {
                            setTimeout(function() {
                                if (self.temporaryAddList.length != 0) {
                                    if (!Util._isEmpty(INSTANCE_TOAST)) {
                                        INSTANCE_TOAST.close();
                                    }
                                    INSTANCE_TOAST = Util.toast(MINT, self.$t('deviceOnline') + ":" + self.getPOrN(device.position, device.name))
                                    self.deviceList.push.apply(self.deviceList, self.temporaryAddList);
                                    if (self.myChart.length > 0) {
                                        self.getMesh(self.temporaryAddMacs);
                                    }
                                    self.$store.commit("setList", self.deviceList);
                                    self.temporaryAddList = [];
                                    self.temporaryAddMacs = [];
                                }
                            }, 4000);
                        }
                        $.each(self.deviceList, function(i, item) {
                            if (item.mac == device.mac) {
                                isExist = false;
                            }
                        });
                        if (isExist) {
                            device = self.setPair(device);
                            self.temporaryAddList.push(device);
                            self.temporaryAddMacs.push(device.mac);
                        }
                    }

                },
                onDeviceLost: function (mac) {
                    var self = this;
                    if (!Util._isEmpty(mac)) {
                        var lenDel = self.temporaryDelList.length;
                        if (self.temporaryDelList.length == 0) {
                            setTimeout(function() {
                                if (self.temporaryDelList.length != 0) {
                                    var item = {};
                                    for (var i = self.deviceList.length - 1; i >= 0; i--) {
                                        item = self.deviceList[i];
                                        if (self.temporaryDelList.indexOf(item.mac) != -1) {
                                            self.deviceList.splice(i, 1);
                                        }
                                    }
                                    if (!Util._isEmpty(INSTANCE_TOAST)) {
                                        INSTANCE_TOAST.close();
                                    }
                                    INSTANCE_TOAST = Util.toast(MINT, self.$t('deviceOffline') + ":" + self.getPOrN(item.position, item.name));
                                    var list = [];
                                    $.each(self.debugList, function(i, item) {
                                        if (self.temporaryDelList.indexOf(item.mac) == -1) {
                                            list.push(item)
                                        }
                                    })
                                    self.debugList = list;
                                    if (!Util._isEmpty(self.myChart) && self.myChart.length > 0) {
                                        self.disposeChart();
                                        self.getInitData();
                                        self.getChartData();
                                    }
                                    self.$store.commit("setList", self.deviceList);
                                    self.temporaryDelList = [];
                                }
                            }, 3000);
                        }
                        self.temporaryDelList.push(mac);
                    }

                },
                debugResult: function(res) {
                    var self = this;
                    console.log(res);
                    if (!Util._isEmpty(res)) {
                        res = JSON.parse(res);
                        self.debugList = Util.uniqeByKeys(res.result, ["mac"]);
                    }
                    self.getInitData();
                    MINT.Indicator.close();
                }
            },
            components: {
                "v-debugInfo": debugInfo
            }

        });
        return Debug;
    });