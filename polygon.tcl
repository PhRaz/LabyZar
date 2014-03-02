#
# Fonctions de calcul du polygone représentant la surface du chemin.
#
# numéro des positions sur un point
#
#  -+-----------------> X
#   |
#   |   0     1
#   |    +---+
#   |    |   |
#   |    +---+
#   |   3     2
#   |
#   v
#   Y

# direction x, -x, y, -y
proc check_path {laby face x y direction} {

    global laby_data

    set size $laby_data($laby.size)
    set index [expr $x * $size + $y]
    set point [lindex $laby_data($laby.face.$face.grid) $index]
    if {[lindex $point $direction] == 2} {
	return 1
    }
    return 0
}

proc polygon {laby face} {

    global laby_data
    global polygon

    set complete 0
    set grid $laby_data($laby.face.$face.grid)

    # On commence par positionner le curseur sur le premier point en haut à
    # gauche dans la grille du labyrinthe.

    set x 0
    set y 0

    # Ce point est vu comme un carré, on se place sur le point en haut à gauche
    # de ce carré.

    set position 0

    # Premier point du polygone.

    set polygon($face) [list]
    lappend polygon($face) [expr $x - 0.2] [expr $y - 0.2]

    while { ! $complete } {

	puts "TRACE x $x y $y"

	switch -- $position {

	    0 {
		# si il y a un chemin vers le point au dessus
		if {[check_path $laby $face $x $y 3]} {
		    # aller vers ce point en se positionnant sur le point en bas à gauche
		    set y [expr $y - 1]
		    set position 3
		    # ajouter un point dans la liste du polygone
		    lappend polygon($face) [expr $x - 0.2] [expr $y + 0.2]
		} else {
		    # rester sur le même point aller vers la position en haut à droite
		    set position 1
		    # ajouter un point dans la liste du polygone
		    lappend polygon($face) [expr $x + 0.2] [expr $y - 0.2]
		}
	    }

	    1 {
		if {[check_path $laby $face $x $y 0]} {
		    set x [expr $x + 1]
		    set position 0
		    lappend polygon($face) [expr $x - 0.2] [expr $y - 0.2]
		} else {
		    set position 2
		    lappend polygon($face) [expr $x + 0.2] [expr $y + 0.2]
		}
	    }

	    2 {
		if {[check_path $laby $face $x $y 2]} {
		    set y [expr $y + 1]
		    set position 1
		    lappend polygon($face) [expr $x + 0.2] [expr $y - 0.2]
		} else {
		    set position 3
		    lappend polygon($face) [expr $x - 0.2] [expr $y + 0.2]
		}
	    }

	    3 {
		if {[check_path $laby $face $x $y 1]} {
		    set x [expr $x - 1]
		    set position 2
		    lappend polygon($face) [expr $x + 0.2] [expr $y + 0.2]
		} else {
		    set position 0
		    lappend polygon($face) [expr $x - 0.2] [expr $y - 0.2]
		}
	    }
	}
	set complete [expr (($x == 0) && ($y == 0) && ($position == 0)) ]
    }
}

proc polygon_draw {canvas face} {

    global polygon

    $canvas create rectangle 10 10 100 100 -fill white
    $canvas create polygon 10 10 120 30 130 200 -fill red

    for {set i 0} {$i < [llength $polygon($face)]} {incr i} {
	puts "$i : [lindex $polygon($face) $i]"
    	lreplace polygon($face) $i $i [expr [lindex $polygon($face) $i] * 100]
    }

    $canvas create polygon $polygon($face) -fill white

    update
}
