* A ring with two inverters

.include 'include/components/inverter_nangate.sp'
.include 'include/circuits/ring.sp'
.include 'include/models/VTL.sp'
.param Vdd = 1

.data dataset mer
+ file = 'ring_nangate_VTL_T_Leff_Tox.param' T = 1 Leff = 2 Tox = 3
.enddata

.end
