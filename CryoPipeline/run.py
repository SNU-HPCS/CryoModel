#!/usr/bin/env python3.8

import argparse
import os
from subprocess import PIPE, run

def arg_parse ():
    parser = argparse.ArgumentParser ()
    parser.add_argument ("--temperature", "-t", help="Target temeprature (i.e., 300K, 77K, or 4K)", type=int, default=300)
    parser.add_argument ("--node", "-n", help="Technology node (i.e., 45nm)", type=int, default=45)
    parser.add_argument ("--vdd", "-d", help="Supply voltage", type=float, default=0)
    parser.add_argument ("--vth", "-r", help="Threshold voltage at 300K (i.e., Vth_300k)", type=float, default=0)
    parser.add_argument ("--design_name", "-dn", type=str, default="router_wrap")
    args = parser.parse_args ()
    return args


def set_targets (design_name):
    dir_names = ["./dc_compile/logic_synthesis/", "./dc_compile/critical_path_extraction/"]
    file_list = list ()
    for dir_name in dir_names:
        file_list = file_list + [dir_name+name_ for name_ in os.listdir (dir_name)]

    for file_name in file_list:
        if ".tcl" in file_name:
            f = open (file_name, "r")
            nf = open (file_name+"_", "w")
            lines = f.readlines ()
            for line in lines:
                if "set TOP_MODULE" in line:
                    nf.write ("set TOP_MODULE {}\n".format (design_name))
                else:
                    nf.write (line)
            f.close ()
            nf.close ()
            os.system ("rm {}".format (file_name))
            os.system ("mv {} {}".format (file_name+"_", file_name))


def run_synthesis (design_name, temperature):
    if not os.path.isfile ("./latency_result/critical_path_300k"):
        if not os.path.isfile ("./{}_300k.ddc".format (design_name)):
            os.system ("make dc-topo-300k")
    if not os.path.isfile ("./latency_result/critical_path_300k_nowire"):
        if not os.path.isfile ("./{}_300k_nowire.ddc".format (design_name)):
            os.system ("make dc-topo-300k-nowire")
    if not os.path.isfile ("./latency_result/critical_path_{}k".format (temperature)):
        if not os.path.isfile ("./{}_{}k.ddc".format (design_name, temperature)):
            os.system ("make dc-topo-{}k".format (temperature))
    if not os.path.isfile ("./latency_result/critical_path_{}k_nowire".format (temperature)):
        if not os.path.isfile ("./{}_{}k_nowire.ddc".format (design_name, temperature)):
            os.system ("make dc-topo-{}k-nowire".format (temperature))


def critical_path_analysis (design_name, temperature):

    f = open ("./latency_result/{}_critical_path_{}k".format (design_name, temperature))
    lines = f.readlines ()
    paths = list ()
    token = 0
    for line in lines:
        if token == 0 and "clock network delay (ideal)" in line:
            token += 1
        elif token == 1 and "/" in line:
            paths.append ("/".join (line.split ("/")[:-2])+"*")
        elif token == 1 and "library setup time" in line:
            break
    return list (dict.fromkeys (paths))


def insert_paths (temperature, paths):
    file_name = "dc_compile/critical_path_extraction/critical_path_{}k_nowire.tcl".format (temperature)
    f = open (file_name, "r")
    nf = open (file_name+"_", "w")

    command = "redirect ${REPORT_DIR}/${TOP_MODULE}_critical_path_" + str (temperature) + "k_nowire " + \
                "{report_timing"
    for path in [paths[0], paths[-1]]:
        command += " -through [get_pins -of_objects {" + path + "}]"
    command += "}\n"

    lines = f.readlines ()
    for line in lines:
        if "report_timing" in line:
            nf.write (command)
        else:
            nf.write (line)
    f.close ()
    nf.close ()
    os.system ("rm {}".format (file_name))
    os.system ("mv {} {}".format (file_name+"_", file_name))



def run_delay_extraction (design_name, temperature):
    
    # 300K critical path (transistor + wire).
    if not os.path.isfile ("./latency_result/{}_critical_path_300k".format (design_name)):
        os.system ("make critical-300k")
    
    # 300K critical path (transistor only).
    if not os.path.isfile ("./latency_result/{}_critical_path_300k_nowire".format (design_name)):
        paths = critical_path_analysis (design_name, 300)
        insert_paths (300, paths)
        os.system ("make critical-300k-nowire")
    
    # Critical path at target temperature (transistor + wire).
    if not os.path.isfile ("./latency_result/{}_critical_path_{}k".format (design_name, temperature)):
        os.system ("make critical-{}k".format (temperature))

    # Critical path at target temperature (transistor only).
    if not os.path.isfile ("./latency_result/{}_critical_path_{}k_nowire".format (design_name, temperature)):
        paths = critical_path_analysis (design_name, temperature)
        insert_paths (temperature, paths)
        os.system ("make critical-{}k-nowire".format (temperature))
    

def run_pgen (temperature, node=45, vdd=None, vth=None):
    pgen_output = None
    if temperature >= 77:
        if vdd == None and vth == None:
            result = run ("python ../CryoMOSFET/CryoMOSFET_77K/pgen.py -n {} -t {}".format \
            (node, temperature), stdout=PIPE, stderr=PIPE, universal_newlines=True, shell=True)
        else:
            result = run ("python ../CryoMOSFET/CryoMOSFET_77K/pgen.py -n {} -d {} -r {} -t {}".format \
                (node, vdd, vth, temperature), stdout=PIPE, stderr=PIPE, universal_newlines=True, shell=True)
    else:
        if vdd == None and vth == None:
            result = run ("python ../CryoMOSFET/CryoMOSFET_4K/pgen.py -n {} -t {}".format \
                (node, temperature), stdout=PIPE, stderr=PIPE, universal_newlines=True, shell=True)
        else:
            result = run ("python ../CryoMOSFET/CryoMOSFET_4K/pgen.py -n {} -d {} -r {} -t {}".format \
                (node, vdd, vth, temperature), stdout=PIPE, stderr=PIPE, universal_newlines=True, shell=True)
    return result.stdout


def report_perf_power (design_name, temperature, node, vdd, vth):
    
    critical_delays = list ()
    dynamic_powers = list ()
    static_powers = list ()
    total_powers = list ()
    file_names = ["300k", "300k_nowire", "{}k".format (temperature), "{}k_nowire".format (temperature)]
    
    for file_name in file_names:
        f = open ("./latency_result/{}_critical_path_".format (design_name)+file_name, "r")
        lines = f.readlines ()
        for line in lines:
            if "data arrival time" in line:
                critical_delays.append (float (line.split ()[-1]))
                break
        f.close ()
        f = open ("./latency_result/{}_power_".format (design_name)+file_name, "r")
        lines = f.readlines ()
        for line in lines:
            data = line.split ()
            if len (data) < 6:
                continue
            elif design_name in data[0]:
                dynamic_powers.append (float (data[1])*1e-6 + float (data[2])*1e-6)
                static_powers.append (float (data[3])*1e-9)
                total_powers.append (float (data[4])*1e-6)
    
    # If the wire-delay value is negative,
    if critical_delays[0] < critical_delays[1]:
        critical_delays[1] = critical_delays[0]
    if critical_delays[2] < critical_delays[3]:
        critical_delays[3] = critical_delays[2]

    critical_delays_total = list ()
    critical_delays_tran = list ()
    critical_delays_wire = list ()
    powers_total = list ()
    powers_static = list ()
    powers_dynamic = list ()

    critical_delays_total = [critical_delays[0], critical_delays[2]]
    critical_delays_tran = [critical_delays[1], critical_delays[3]]
    critical_delays_wire = [critical_delays[0] - critical_delays[1], critical_delays[2] - critical_delays[3]]
    powers_total = [total_powers[0], total_powers[2]]
    powers_static = [static_powers[0], static_powers[2]]
    powers_dynamic = [dynamic_powers[0], dynamic_powers[2]]

    #pgen_300k = run_pgen (300, node) # ITRS.
    pgen_300k = run_pgen (300, node, 1.25, 0.46893) # Intel 45nm CPU.
    pgen_temp = run_pgen (temperature, node, vdd, vth)

    pgen_ref = dict ()
    lines = pgen_300k.split ("\n")
    for line in lines:
        if "Vdd" in line:
            pgen_ref["Vdd"] = float (line.split ()[1])
        if "Ion" in line:
            pgen_ref["Ion"] = float (line.split ()[1])
        if "Isub" in line:
            pgen_ref["Isub"] = float (line.split ()[1])
        if "Igate" in line:
            pgen_ref["Igate"] = float (line.split ()[1])
            break

    pgen_target = dict ()
    lines = pgen_temp.split ("\n")
    for line in lines:
        if "Vdd" in line:
            pgen_target["Vdd"] = float (line.split ()[1])
        if "Ion" in line:
            pgen_target["Ion"] = float (line.split ()[1])
        if "Isub" in line:
            pgen_target["Isub"] = float (line.split ()[1])
        if "Igate" in line:
            pgen_target["Igate"] = float (line.split ()[1])
            break

    # Transistor speed-up (Ion/Vdd)
    trans_speedup = (pgen_target["Ion"]/pgen_target["Vdd"]) / (pgen_ref["Ion"]/pgen_ref["Vdd"])
    # Dynamic power reduction (Vdd^2)
    dyn_reduction = ((pgen_target["Vdd"]**2) / (pgen_ref["Vdd"]**2))
    # Static power reduction (Isub+Igate)
    stat_reduction = ((pgen_target["Isub"]+pgen_target["Igate"]) / (pgen_ref["Isub"]+pgen_ref["Igate"]))

    critical_delays_tran[1] = critical_delays_tran[1] / trans_speedup
    critical_delays_total[1] = critical_delays_tran[1] + critical_delays_wire[1]
    powers_dynamic[1] = powers_dynamic[1] * dyn_reduction
    powers_static[1] = powers_static[1] * stat_reduction
    powers_total[1] = powers_dynamic[1] + powers_static[1]

    print ("================")
    print ("Critical-path delay at 300K")
    print ("  Total delay:\t\t{0:.6f} [ns]".format (critical_delays_total[0]))
    print ("    Transistor:\t\t{0:.6f} [ns]".format (critical_delays_tran[0]))
    print ("    Wire:\t\t{0:.6f} [ns]\n".format (critical_delays_wire[0]))

    print ("Critical-path delay at {}K".format (temperature))
    print ("  Total delay:\t\t{0:.6f} [ns]".format (critical_delays_total[1]))
    print ("    Transistor:\t\t{0:.6f} [ns]".format (critical_delays_tran[1]))
    print ("    Wire:\t\t{0:.6f} [ns]\n".format (critical_delays_wire[1]))
    
    print ("Speed-up:\t\t{0:.6f} times\n".format (critical_delays_total[0]/critical_delays_total[1]))

    print ("================")
    print ("Power consumption at 300K")
    print ("  Total power:\t\t{0:.6f} [W]".format (powers_total[0]))
    print ("    Static power:\t{0:.6f} [W]".format (powers_static[0]))
    print ("    Dynamic power:\t{0:.6f} [W]\n".format (powers_dynamic[0]))

    print ("Power consumption at {}K".format (temperature))
    print ("  Total power:\t\t{0:.6f} [W]".format (powers_total[1]))
    print ("    Static power:\t{0:.6f} [W]".format (powers_static[1]))
    print ("    Dynamic power:\t{0:.6f} [W]\n".format (powers_dynamic[1]))
    
    print ("Power reduction:\t{0:.6f} times\n".format (powers_total[0]/powers_total[1]))


def clean_up ():
    os.system ("make clean")


def main ():

    args = arg_parse ()
    temperature = args.temperature
    node = args.node
    #vdd = args.vdd if args.vdd > 0 else 1.0     # Vdd of 45nm ITRS
    #vth = args.vth if args.vth > 0 else 0.46893 # Vth of 45nm ITRS
    vdd = args.vdd if args.vdd > 0 else 1.25     # Vdd of 45nm Intel CPU
    vth = args.vth if args.vth > 0 else 0.46893  # Vth of 45nm Intel CPU
    design_name = args.design_name

    # Input-requirement checking.
    if node != 45:
        print ("Currently, CryoPipeline only supports 45nm.")
        exit ()
    if not any ((temperature == key_) for key_ in [300, 77, 4]):
        print ("Currently, CryoPipeline only supports 300K, 77K, and 4K.")
        exit ()

    run_pgen (temperature, node, vdd, vth)
    set_targets (design_name)
    run_synthesis (design_name, temperature)
    run_delay_extraction (design_name, temperature)
    report_perf_power (design_name, temperature, node, vdd, vth)
    clean_up ()

    
if __name__ == "__main__":
    main ()
