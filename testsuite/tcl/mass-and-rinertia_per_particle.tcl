# Copyright (C) 2011,2012,2013,2014,2015,2016 The ESPResSo project
#  
# This file is part of ESPResSo.
#  
# ESPResSo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  
# ESPResSo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#  
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#
source "tests_common.tcl"

require_feature "MASS"
require_feature "ROTATIONAL_INERTIA"
require_feature "LANGEVIN_PER_PARTICLE"

puts "------------------------------------------------"
puts "- Testcase mass-and-rinertia_per_particle.tcl running on [format %02d [setmd n_nodes]] nodes: -"
puts "------------------------------------------------"
puts "------------------------------------------------"

proc test_mass-and-rinertia_per_particle {test_case} {
    # make real random draw
    set cmd "t_random seed"
    for {set i 0} {$i < [setmd n_nodes]} { incr i } {
	  lappend cmd [expr [pid] + $i] }
    eval $cmd

    set gamma0 1.
    set gamma1 1. 
    
    # Decelleration
    setmd skin 0
    setmd time_step 0.007
    thermostat langevin 0 $gamma0 
    cellsystem nsquare 
    #-no_verlet_lists
    set J "10 10 10"
    set mass 12.74

    part deleteall
    part 0 pos 0 0 0 mass $mass rinertia [lindex $J 0] [lindex $J 1] [lindex $J 2] omega_body 1 1 1 v 1 1 1
    part 1 pos 0 0 0 mass $mass rinertia [lindex $J 0] [lindex $J 1] [lindex $J 2] omega_body 1 1 1 v 1 1 1
    puts "\n"
    switch $test_case {
        0 {
            puts "------------------------------------------------"
            puts "Test $test_case: no particle specific values"
            puts "------------------------------------------------"
            set gamma1 $gamma0 
        }
        1 {
            puts "------------------------------------------------"
            puts "Test $test_case: particle specific gamma but not temperature"
            puts "------------------------------------------------"
            part 0 gamma $gamma0
            part 1 gamma $gamma1
        }
        2 {
            puts "------------------------------------------------"
            puts "Test $test_case: particle specific temperature but not gamma"
            puts "------------------------------------------------"
            part 0 temp 0.0
            part 1 temp 0.0
            set gamma1 $gamma0 
        }
        3 {
            puts "------------------------------------------------"
            puts "Test $test_case: both particle specific gamma and temperature"
            puts "------------------------------------------------"
            part 0 gamma $gamma0 temp 0.0
            part 1 gamma $gamma1 temp 0.0
        }
    }
    setmd time 0
    for {set i 0} {$i <100} {incr i} {
        for {set k 0} {$k <3} {incr k} {
            if {[has_feature "VERLET_STEP4_VELOCITY"]} {
                set tolerance_o 1.25E-4
            } else {
                set tolerance_o 1.0E-2
            }
            set do0 [expr abs([lindex [part 0 print omega_body] $k] -exp(-$gamma0*[setmd time] /[lindex $J $k]))]
            set do1 [expr abs([lindex [part 1 print omega_body] $k] -exp(-$gamma1*[setmd time] /[lindex $J $k]))]
            if { $do0 > $tolerance_o || $do1 > $tolerance_o } {
                error_exit "Friction Deviation in omega too large. $i $k $do0 $do1"
            }
            if {[has_feature "VERLET_STEP4_VELOCITY"]} {
                set tolerance_v 4.5E-5
            } else {
                set tolerance_v 1.0E-2
            }
            set dv0 [expr abs([lindex [part 0 print v] $k] -exp(-$gamma0*[setmd time] / $mass))]
            set dv1 [expr abs([lindex [part 1 print v] $k] -exp(-$gamma1*[setmd time] / $mass))]
            if { $dv0 > $tolerance_v || $dv1 > $tolerance_v } {
                error_exit "Friction Deviation in v too large. $i $k $dv0 $dv1"
            }
        }
        integrate 10
    }


    #Accelerated motion
    # Left out, since not use of thermostat
    part deleteall


    # thermalization
    # Checks if every degree of freedom has 1/2 kT of energy, even when
    # mass and inertia tensor are active

    # 2 different langevin parameters for particles
    set gamma(0) 1.0
    set gamma(1) 2.0
    set temp(0) 2.5
    set temp(1) 2.0
    set gamma_rot_1(0) [expr (0.2 + [t_random]) * 20]
    set gamma_rot_2(0) [expr (0.2 + [t_random]) * 20]
    set gamma_rot_3(0) [expr (0.2 + [t_random]) * 20]
    set gamma_rot_1(1) [expr (0.2 + [t_random]) * 20]
    set gamma_rot_2(1) [expr (0.2 + [t_random]) * 20]
    set gamma_rot_3(1) [expr (0.2 + [t_random]) * 20]

    set box 10
    setmd box_l $box $box $box
    set kT 1.5
    set halfkT 0.75
    
    thermostat langevin $kT 1

    # no need to rebuild Verlet lists, avoid it
    setmd skin 1.0
    setmd time_step 0.008

    set n 200
    set mass [expr (0.2 + [t_random]) *20]
    set j1 [expr (0.2 + [t_random]) * 7]
    set j2 [expr (0.2 + [t_random]) * 7]
    set j3 [expr (0.2 + [t_random]) * 7]

    for {set i 0} {$i<$n} {incr i} {
        for {set k 0} {$k<2} {incr k} {
            set ind [expr $i + $k*$n]
            set pos0($ind) [list [expr [t_random] *$box] [expr [t_random] * $box] [expr [t_random] * $box]]
            part [expr $i + $k*$n] pos [lindex $pos0($ind) 0] [lindex $pos0($ind) 1] [lindex $pos0($ind) 2] rinertia $j1 $j2 $j3 mass $mass
            switch $test_case {
                1 {part [expr $i + $k*$n] gamma $gamma($k) gamma_rot $gamma_rot_1($k) $gamma_rot_2($k) $gamma_rot_3($k)}
                2 {part [expr $i + $k*$n] temp $temp($k)}
                3 {part [expr $i + $k*$n] gamma $gamma($k) gamma_rot $gamma_rot_1($k) $gamma_rot_2($k) $gamma_rot_3($k) temp $temp($k)}
            }
        }
    }

    for {set k 0} {$k<2} {incr k} {
        set vx2($k) 0.
        set vy2($k) 0.
        set vz2($k) 0.
        set ox2($k) 0.
        set oy2($k) 0.
        set oz2($k) 0.
        set dx2($k) 0.
        set dy2($k) 0.
        set dz2($k) 0.
    }

    set loops 100

    puts "Thermalizing..."
    set therm_steps 1200
    integrate $therm_steps
    puts "Measuring..."

    for {set i 0} {$i <$loops} {incr i} {
        set int_steps 100
        integrate $int_steps
        # Get kinetic energy in each degree of freedom for all particles
        for {set p 0} {$p <$n} {incr p} {
            for {set k 0} {$k<2} {incr k} {
                set ind [expr $p + $k*$n]
                set v [part [expr $p + $k*$n] print v]
                set o [part [expr $p + $k*$n] print omega_body]
                set pos [part [expr $p + $k*$n] print pos]
                set ox2($k) [expr $ox2($k) +pow([lindex $o 0],2)]
                set oy2($k) [expr $oy2($k) +pow([lindex $o 1],2)]
                set oz2($k) [expr $oz2($k) +pow([lindex $o 2],2)]
                set vx2($k) [expr $vx2($k) +pow([lindex $v 0],2)]
                set vy2($k) [expr $vy2($k) +pow([lindex $v 1],2)]
                set vz2($k) [expr $vz2($k) +pow([lindex $v 2],2)]
                if {$i == [expr $loops - 1]} {
                    set dx2($k) [expr $dx2($k) + pow([expr [lindex $pos 0] - [lindex $pos0($ind) 0]], 2)]
                    set dy2($k) [expr $dy2($k) + pow([expr [lindex $pos 1] - [lindex $pos0($ind) 1]], 2)]
                    set dz2($k) [expr $dz2($k) + pow([expr [lindex $pos 2] - [lindex $pos0($ind) 2]], 2)]
                }
            }
        }
    }

    set tolerance 0.15
    for {set k 0} {$k<2} {incr k} {
        set Evx($k) [expr 0.5 * $mass *$vx2($k)/$n/$loops]
        set Evy($k) [expr 0.5 * $mass *$vy2($k)/$n/$loops]
        set Evz($k) [expr 0.5 * $mass *$vz2($k)/$n/$loops]

        set Eox($k) [expr 0.5 * $j1 *$ox2($k)/$n/$loops]
        set Eoy($k) [expr 0.5 * $j2 *$oy2($k)/$n/$loops]
        set Eoz($k) [expr 0.5 * $j3 *$oz2($k)/$n/$loops]

        if {$test_case == 2 || $test_case ==3} {
            set halfkT [expr $temp($k)/2.]
        }

        set dv($k) [expr 1./3. *($Evx($k) +$Evy($k) +$Evz($k))/$halfkT-1.]
        set do($k) [expr 1./3. *($Eox($k) +$Eoy($k) +$Eoz($k))/$halfkT-1.]
        
        if {$test_case == 1 || $test_case == 3} {
            set gamma_tr $gamma($k)
        } else {
            set gamma_tr 1
        }
        # translational diffusion
        set D_tr($k) [expr 2 * $halfkT / $gamma_tr]
        set dt [expr ($therm_steps + $int_steps * $loops) * [setmd time_step]]
        set dt0 [expr $mass / $gamma_tr]
        # translational variance: after a closed-form integration of the Langevin EOM
        set sigma2_tr($k) [expr $D_tr($k) * (6 * $dt + 3 * $dt0 * (-3 + 4 * exp(-$dt / $dt0) - exp(-2 * $dt / $dt0)))]
        set dr($k) [expr (($dx2($k)+$dy2($k)+$dz2($k))/$n - $sigma2_tr($k)) / $sigma2_tr($k)]

        set dox($k) [expr ($Eox($k))/$halfkT-1.]
        set doy($k) [expr ($Eoy($k))/$halfkT-1.]
        set doz($k) [expr ($Eoz($k))/$halfkT-1.]
        
        puts "\n"
        puts "1/2 kT = $halfkT"
        puts "translation: $Evx($k) $Evy($k) $Evz($k) rotation: $Eox($k) $Eoy($k) $Eoz($k)"

        puts "Deviation in translational energy: $dv($k)"
        puts "Deviation in rotational energy: $do($k)"
        puts "Deviation in translational dispersion: $dr($k)"
        puts "Deviation in rotational energy per degrees of freedom: $dox($k) $doy($k) $doz($k)"

        if { abs($dv($k)) > $tolerance } {
           error "Relative deviation in translational energy too large: $dv($k)"
        }
        if { abs($do($k)) > $tolerance } {
           puts "Moment of inertia principal components: $j1 $j2 $j3"
           error "Relative deviation in rotational energy too large: $do($k)"
        }
        if { abs($dr($k)) > $tolerance } {
           error "Relative deviation in translational dispersion too large: $dr($k)"
       }
        if { abs($dox($k)) > $tolerance } {
           puts "Moment of inertia principal components: $j1 $j2 $j3"
           error "Relative deviation in rotational energy per the body axis X is too large: $dox($k)"
        }
        if { abs($doy($k)) > $tolerance } {
           puts "Moment of inertia principal components: $j1 $j2 $j3"
           error "Relative deviation in rotational energy per the body axis Y is too large: $doy($k)"
        }
        if { abs($doz($k)) > $tolerance } {
           puts "Moment of inertia principal components: $j1 $j2 $j3"
           error "Relative deviation in rotational energy per the body axis Z is too large: $doz($k)"
        }
    }
}

# the actual testing
for {set i 0} {$i < 4} {incr i} {
    test_mass-and-rinertia_per_particle $i
}

exit 0
