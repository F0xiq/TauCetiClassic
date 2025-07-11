/obj/machinery/computer/drone_control
	name = "Maintenance Drone Control"
	desc = "Used to monitor the station's drone population and the assembler that services them."
	icon = 'icons/obj/computer.dmi'
	icon_state = "drone_control"
	state_broken_preset = "powerb"
	state_nopower_preset = "power0"
	light_color = "#b88b2e"
	req_access = list(access_engine_equip)
	circuit = /obj/item/weapon/circuitboard/drone_control

	//Used when pinging drones.
	var/drone_call_area = "Engineering"
	//Used to enable or disable drone fabrication.
	var/obj/machinery/drone_fabricator/dronefab

/obj/machinery/computer/drone_control/interact(user)
	if(isdrone(user))
		to_chat(user, "<span class='warning'>Access Denied.</span>")
	else
		..()

/obj/machinery/computer/drone_control/ui_interact(mob/user)
	var/dat
	dat += "<B>Maintenance Units</B><BR>"

	for(var/mob/living/silicon/robot/drone/D as anything in drone_list)
		dat += "<BR>[D.real_name] ([D.stat == DEAD ? "<span class='red'>INACTIVE</span>" : "<span class='green'>ACTIVE</span>"])"
		dat += "<BR>Cell charge: [D.cell.charge]/[D.cell.maxcharge]."
		dat += "<BR>Currently located in: [get_area(D)]."
		dat += "<BR><A href='byond://?src=\ref[src];resync=\ref[D]'>Resync</A> | <A href='byond://?src=\ref[src];shutdown=\ref[D]'>Shutdown</A>"

	dat += "<BR><BR><B>Request drone presence in area:</B> <A href='byond://?src=\ref[src];setarea=1'>[drone_call_area]</A> (<A href='byond://?src=\ref[src];ping=1'>Send ping</A>)"

	dat += "<BR><BR><B>Drone fabricator</B>: "
	dat += "[dronefab ? "<A href='byond://?src=\ref[src];toggle_fab=1'>[(dronefab.produce_drones && !(dronefab.stat & NOPOWER)) ? "ACTIVE" : "INACTIVE"]</A>" : "<span class='red'><b>FABRICATOR NOT DETECTED.</b></span> (<A href='byond://?src=\ref[src];search_fab=1'>search</a>)"]"

	var/datum/browser/popup = new(user, "computer", null, 400, 500)
	popup.set_content(dat)
	popup.open()


/obj/machinery/computer/drone_control/Topic(href, href_list)
	. = ..()
	if(!.)
		return

	if(!allowed(usr))
		to_chat(usr, "<span class='warning'>Access denied.</span>")
		return FALSE

	if (href_list["setarea"])

		//Probably should consider using another list, but this one will do.
		var/t_area = input("Select the area to ping.", "Set Target Area", null) as null|anything in tagger_locations

		if(!t_area)
			return FALSE

		drone_call_area = t_area
		to_chat(usr, "<span class='notice'>You set the area selector to [drone_call_area].</span>")

	else if (href_list["ping"])

		to_chat(usr, "<span class='notice'>You issue a maintenance request for all active drones, highlighting [drone_call_area].</span>")
		for(var/mob/living/silicon/robot/drone/D as anything in drone_list)
			if(D.client && D.stat == CONSCIOUS)
				to_chat(D, "-- Maintenance drone presence requested in: [drone_call_area].")

	else if (href_list["resync"])

		var/mob/living/silicon/robot/drone/D = locate(href_list["resync"])

		if(D.emagged || istype(D, /mob/living/silicon/robot/drone/maintenance/malfuction))
			to_chat(usr, "<span class='warning'>Дрон не отвечает на запросы.</span>")
		else if(D.stat != DEAD)
			to_chat(usr, "<span class='notice'>You issue a law synchronization directive for the drone.</span>")
			D.law_resync()

	else if (href_list["shutdown"])

		var/mob/living/silicon/robot/drone/D = locate(href_list["shutdown"])

		if(D.emagged || istype(D, /mob/living/silicon/robot/drone/maintenance/malfuction))
			to_chat(usr, "<span class='warning'>Система самоуничтожения этого дрона неисправна.</span>")
		else if(D.stat != DEAD)
			to_chat(usr, "<span class='notice'>You issue a kill command for the unfortunate drone.</span>")
			message_admins("[key_name_admin(usr)] issued kill order for drone [key_name_admin(D)] from control console. [ADMIN_JMP(usr)]")
			log_game("[key_name(usr)] issued kill order for [key_name(src)] from control console.")
			D.shut_down()

	else if (href_list["search_fab"])
		if(dronefab)
			return

		for(var/obj/machinery/drone_fabricator/fab in oview(3,src))

			if(fab.stat & NOPOWER)
				continue

			dronefab = fab
			to_chat(usr, "<span class='notice'>Drone fabricator located.</span>")
			return

		to_chat(usr, "<span class='warning'>Unable to locate drone fabricator.</span>")

	else if (href_list["toggle_fab"])

		if(!dronefab)
			return FALSE

		if(get_dist(src,dronefab) > 3)
			dronefab = null
			to_chat(usr, "<span class='warning'>Unable to locate drone fabricator.</span>")
			return

		dronefab.produce_drones = !dronefab.produce_drones
		to_chat(usr, "<span class='notice'>You [dronefab.produce_drones ? "enable" : "disable"] drone production in the nearby fabricator.</span>")

	updateUsrDialog()
