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
proc polygon_check_path {laby face x y direction} {

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

    set WALL_WIDTH 0.45

    set complete 0
    set size $laby_data($laby.size)
    set grid $laby_data($laby.face.$face.grid)

    # On commence par positionner le curseur sur le premier point en haut à
    # gauche dans la grille du labyrinthe.

    set x 0
    set y 0

    # Ce point est vu comme un carré, on se place sur le point en haut à gauche
    # de ce carré.

    set position 0

    # Premiers points du polygone, le cadre du labyrinthe.

    set polygon($face) [list]

    lappend polygon($face) \
	[expr -1 + $WALL_WIDTH] [expr -1 + $WALL_WIDTH] \
	[expr $size - $WALL_WIDTH] [expr -1 + $WALL_WIDTH] \
	[expr $size - $WALL_WIDTH] [expr $size - $WALL_WIDTH] \
	[expr -1 + $WALL_WIDTH] [expr $size - $WALL_WIDTH] \
	[expr -1 + $WALL_WIDTH] [expr -1 + $WALL_WIDTH]

    lappend polygon($face) [expr $x - $WALL_WIDTH] [expr $y - $WALL_WIDTH]

    while { ! $complete } {

	puts "TRACE x $x y $y"

	switch -- $position {

	    0 {
		# si il y a un chemin vers le point au dessus
		if {[polygon_check_path $laby $face $x $y 3]} {
		    # aller vers ce point en se positionnant sur le point en bas à gauche
		    set y [expr $y - 1]
		    set position 3
		    # ajouter un point dans la liste du polygone
		    lappend polygon($face) [expr $x - $WALL_WIDTH] [expr $y + $WALL_WIDTH]
		} else {
		    # rester sur le même point aller vers la position en haut à droite
		    set position 1
		    # ajouter un point dans la liste du polygone
		    lappend polygon($face) [expr $x + $WALL_WIDTH] [expr $y - $WALL_WIDTH]
		}
	    }

	    1 {
		if {[polygon_check_path $laby $face $x $y 0]} {
		    set x [expr $x + 1]
		    set position 0
		    lappend polygon($face) [expr $x - $WALL_WIDTH] [expr $y - $WALL_WIDTH]
		} else {
		    set position 2
		    lappend polygon($face) [expr $x + $WALL_WIDTH] [expr $y + $WALL_WIDTH]
		}
	    }

	    2 {
		if {[polygon_check_path $laby $face $x $y 2]} {
		    set y [expr $y + 1]
		    set position 1
		    lappend polygon($face) [expr $x + $WALL_WIDTH] [expr $y - $WALL_WIDTH]
		} else {
		    set position 3
		    lappend polygon($face) [expr $x - $WALL_WIDTH] [expr $y + $WALL_WIDTH]
		}
	    }

	    3 {
		if {[polygon_check_path $laby $face $x $y 1]} {
		    set x [expr $x - 1]
		    set position 2
		    lappend polygon($face) [expr $x + $WALL_WIDTH] [expr $y + $WALL_WIDTH]
		} else {
		    set position 0
		    lappend polygon($face) [expr $x - $WALL_WIDTH] [expr $y - $WALL_WIDTH]
		}
	    }
	}
	set complete [expr (($x == 0) && ($y == 0) && ($position == 0)) ]
    }
}

proc polygon_draw {canvas face} {

    global polygon

    for {set i 0} {$i < [llength $polygon($face)]} {incr i} {
	puts "$i : [lindex $polygon($face) $i]"
    	set polygon($face) [lreplace $polygon($face) $i $i [expr [lindex $polygon($face) $i] * 40 + 60]]
    }

    $canvas create polygon $polygon($face) -fill white -tags $face

    update
}

# compute the points coordinates for the view

proc polygon_points_to_view {laby face} {

    global laby_data
    global laby_display
    global polygon
    global sin_PI_6
    global cos_PI_6

    set size $laby_data($laby.size)

    # Compute the graphic unit length, use float (2.0) and round for better
    # centering of the grids.

    set grid_unit [expr round($laby_display(nb_pixel) / ($size * 2.0 + 2))]

    # Compute the display translation vectors.

    set middle  [expr $laby_display(nb_pixel) / 2]

    # Compute the translation.

    switch $face {
	front {
	    set translation [list \
				 [expr $middle - ($size - 1)  * $grid_unit * $cos_PI_6] \
				 [expr $middle + ($size - 1) * $grid_unit *  $sin_PI_6]]
	}
	top {
	    set translation [list \
				 $middle \
				 [expr $middle - ($size - 1) * 2 * $grid_unit *  $sin_PI_6]]
	}
	side {
	    set translation [list \
				 [expr $middle + ($size - 1) * $grid_unit * $cos_PI_6] \
				 [expr $middle + ($size - 1) * $grid_unit * $sin_PI_6]]
	}
	default {
	    puts "Fatal error"
	    exit 1
	}
    }

    # Translation of the face origin in the display coordinates.

    set x_orig  [lindex $translation 0]
    set y_orig  [lindex $translation 1]

    # Computes the direction and size of base vectors in the display
    # coordinates.

    set dir_x [list \
		   [expr [lindex $laby_display(xy_h.$face) 0 0] * $grid_unit] \
		   [expr [lindex $laby_display(xy_h.$face) 0 1] * $grid_unit]]

    set dir_y [list \
		   [expr [lindex $laby_display(xy_h.$face) 1 0] * $grid_unit] \
		   [expr [lindex $laby_display(xy_h.$face) 1 1] * $grid_unit]]

    # Computes the news point.

    set new_polygon [list]

    puts "Avant"
    puts [array get polygon($face)]

    foreach {x y} $polygon($face) {

	puts "x $x y $y"

	# Compute the point coordinates by using the xy direction
	# vector.

	set ox [expr $x_orig + $x * [lindex $dir_x 0] + $y * [lindex $dir_x 1]]
	set oy [expr $y_orig + $x * [lindex $dir_y 0] + $y * [lindex $dir_y 1]]

	lappend new_polygon $ox $oy
    }

    puts "Après"
    puts [array get new_polygon]

    set polygon($face) $new_polygon
}
