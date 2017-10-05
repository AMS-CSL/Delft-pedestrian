/**
 *  model5
 *  Author: ligte002
 *  Description: 
 */


/**
 *  Description: simulatie voetgangers Delf 
 *  Keuze via geschiktheid van weg
 */
 
model DelftPedestrians
 
 
global {   
	
	//Naam als pre-fix for de outputshapefiles
	string runName <- "default";


	//load network shapefile (shp should contain atrributes:  nr_lans","weight" and "wegtype"
	// the weight in the current Delft network shape are all set to 1 so not influence to be expecte
	// need to try out to see how and what the effects of weights are
	file shape_file_roads  <- file("../includes/netwerk1503.shp") ;

	//load shapefile with starting points of pedestrians (points)
	file shape_file_sources <- file("../includes/parking.shp") ;
 	
	// load shape_file with pois. At this moment pois are represented as points. However in principle this could 
	// also be polygons are linear segments such as parts of a road. An agent should than choose a arbitrary point somewhere
	// in the polygon or along the linear segement.
	file shape_file_pois <- file("../includes/kruisingen2303.shp") ;
	//load shape_file with boundingbox of the network shapefile
	
	file shape_file_bounds <- file("../includes/centrum_boundaries.shp") ;

	//parameter to set the # of agents. Can be change also via the gui
	int capacity <- 10000;
	float value <- 0.1;
	string background;
	
	int nb_inhabitant -> {length (inhabitant)};
	int nb_regionalvisitor -> {length (regionalvisitor)};
	int nb_othervisitor -> {length (othervisitor)};
	int total {nb_inhabitant+nb_regionalvisitor+nb_othervisitor}
	
	
	//distance to search for pois. Can be changed also via the gui
	//int distance <- 500;
	float A <- 0.5;
	float B <- 0.0;
	float C <- 0.5;
	float D <- 0.9;
	float E <- 0.9;
	float F <- 0.0;
	float G <- 0.4;
	float H <- 0.2;
	float I <- 0.4;
	float J <- 0.9;
	float K <- 0.2;
	float L <- 0.1;
	//set the extend of the geometry
	geometry shape <- envelope(shape_file_bounds);
	
	// initialize a counter to keep track on the nr of pois reached by the agents
	//int nbGoalsAchived <- 0;
	
	//intialize a variable of type graph wich contain later the network
	graph the_graph;  	
	
	// parameter which determine the probability a new pedestrion is created at the start location.
	float probabilityOfCreation <- 0.01;
	
	//counter for the number of released pedestrian in the simulation;
	int numberReleasedPedestrians {numberinhabitants+numberregionalvisitors+numberothervisitors} 
	int numberinhabitants <- 0;
	int numberregionalvisitors <- 0;
	int numberothervisitors <- 0;
	//parameter that determines the number of traveled roads it can keep in memory
	//int numberOfRoadsInMemory <- 1000;
	
	//parameter by which the weight is multiplied when road is recently visited
	float followedRoadMemoryDecay <- 0.5;
	

	init {  
			 write "model started"; 	
		//create road species by from the network shapefile an load the attribute names into corresponding attribute of the road species
		
 
		create road from: shape_file_roads with:[Oid::int(read("ObjectID")),nbLanes::int(read("nr_lanes")),at_shop::float(read("shops_1")), at_tourist::float(read("tourist_1")), at_horeca::float(read("horeca_1")), at_cult::float(read("culture_1"))]{} 	
 				write "road visualised";
		//create source species from the shapefile with startign points
		create source from: shape_file_sources with:[id::int(read("id")), capacity::int(read("capacity"))] ;
				 write "sources visualised";	
		//create pois species from the shapefile with pois
		create poi from: shape_file_pois with:[id::int(read("id"))];
				write "crossings visualised";
		//way of assigning weights to the road segments. Simple factor * lenght. Alternatively use weight variable of road to
		//set dynamically the factor
		map<road,float> weights_map <- road as_map (each:: (1 * each.shape.perimeter));
		
		
		the_graph <-  (as_edge_graph(road)) with_weights weights_map; 			

					
	}
	

 


}
 
entities {
	species road {
		int Oid;
		int nbLanes;
		int nrOfPassedInhabitants <- 0;
		int nrOfPassedRegionalVisitors <- 0;
		int nrOfotherVisitors <- 0;	
		int nrOftotalPassedInhabitants <- 0;
		int nrOftotalPassedRegionalVisitors <- 0;
		int nrOftotalPassedotherVisitors <-0;	
		//float partweight;
		//float  gewicht <-0.0;
		int substractedWeight <- 0;
		int indexDirection;
		path geom_visu;
		rgb color <- rgb("gray");
		int nrOfPassedPedestrians <- 0;
		float at_shop;
		float at_tourist;
		float at_horeca;
		float at_cult;
		int nonr_zone;
		int reg_zone;
		int inh_zone;
		float inh_zone_attr;
		float reg_zone_attr;
		float nonr_zone_attr;
		
		
		init{
			
			if at_shop = 0 {at_shop <- 0.001;}
			if at_tourist = 0 {at_tourist <- 0.001;}
			if at_horeca = 0 {at_horeca <- 0.001;}
			if at_cult = 0 {at_cult <- 0.001;}
		
			if inh_zone = 0 {inh_zone_attr <- value;}
			else  {inh_zone_attr <- 1;}
			
			if reg_zone = 0 {reg_zone_attr <-value;}
			else {reg_zone_attr <- 1;}
			
			if nonr_zone = 0 {nonr_zone_attr <-value;}
			else {nonr_zone_attr <- 1;}
		
		}
	
		aspect base {
			draw shape color: rgb("black");
			
		}
		

	}
	

	species source {
		//const parking_icon type: file <- file("../images/parking_icon.gif") ;
		int id;
		int capacity;
		//int capacity <- 10; //slowly release of pedestrians from the parking: 1 at every tick till capacity is reached
 		
 		
		reflex release_pedestrian when: (total < capacity) {
			if flip (probabilityOfCreation){
			int kans <- rnd(10000);
			switch kans {
				match_between [1, 2270] {
					if (numberinhabitants < 49) {
						create inhabitant number: 1 {
							starttime <- time;
							speed <- 0.5;
							//target <- any_location_in(one_of(poi));
							//start <- one_of(source);
							type <- 1;
							location <- source(0);
							startlocation <-location;
							//living_space <- 0.0;
							//tolerance <- 0.0;
							weightShops <- 0.5;
							weightTour <- 0.0;
							weightHoreca <- 0.5;
							weightCult <- 0.9;
							lanes_attribute <- "nbLanes";
							//obstacle_species <- [species(self)];
							//do Choose_Target;
							timebudget <- gauss(4737, 2946);
							do Which_Road;
							if flip(1) {numberinhabitants <-  numberinhabitants +1;}
							else {numberinhabitants}
						}

					} 
			
				}

					match_between [2271, 5857] {
						if (numberregionalvisitors  < 91) {
							create regionalvisitor number: 1 {
								starttime <- time;
								speed <- 0.5;
								//target <- any_location_in(one_of(poi));
								//start <- one_of(source);
								type <- 2;
								location <- source(0);
								//living_space <- 0;
								//tolerance <- 0;
								weightShops <- 0.9;
								weightTour <- 0.0;
								weightHoreca <- 0.4;
								weightCult <- 0.2;
								startlocation <-location;
								lanes_attribute <- "nbLanes";
								//obstacle_species <- [species(self)];
								//do Choose_Target;
								timebudget <- gauss(6351, 3585);
								do Which_Road;
								if flip (1) {numberregionalvisitors <-  numberregionalvisitors +1;}
								else {numberregionalvisitors}
							}

						}	

					}
				match_between [5858, 5978] {
						if (numberothervisitors < 12) {
							create othervisitor number: 1 {
								starttime <- time;
								speed <- 0.5;
								//target <- any_location_in(one_of(poi));
								//start <- one_of(source);
								type <- 3;
								location <- source(0);
								//living_space <- 0;
								//tolerance <- 0;
								weightShops <- 0.4;
								weightTour <- 0.9;
								weightHoreca <- 0.2;
								weightCult <- 0.1;
								startlocation <- location;
								lanes_attribute <- "nbLanes";
								//obstacle_species <- [species(self)];
								//do Choose_Target;
								timebudget <- gauss(8136, 5365);
								do Which_Road;
								if flip (1) {numberothervisitors <-  numberothervisitors +1;}
								else {numberothervisitors}
							}

						
					}
				}
				match_between [5979, 6935] {
					if (numberinhabitants < 49) {
						create inhabitant number: 1 {
							starttime <- time;
							speed <- 0.5;
							//target <- any_location_in(one_of(poi));
							//start <- one_of(source);
							type <- 1;
							location <- source(1);
							startlocation <-location;
							//living_space <- 0.0;
							//tolerance <- 0.0;
							weightShops <- 0.5;
							weightTour <- 0.0;
							weightHoreca <- 0.5;
							weightCult <- 0.9;
							lanes_attribute <- "nbLanes";
							//obstacle_species <- [species(self)];
							//do Choose_Target;
							timebudget <- gauss(4737, 2946);
							do Which_Road;
							if flip (1) {numberinhabitants <-  numberinhabitants +1;}
							else {numberinhabitants}
							
						}

					}

				}
				match_between [6936, 9406] {
					if (numberregionalvisitors < 91) {
						create regionalvisitor number: 1 {
							starttime <- time;
							speed <- 0.5;
							//target <- any_location_in(one_of(poi));
							//start <- one_of(source);
							type <- 2;
							location <- source(1);
							startlocation <-location;
							//living_space <- 0.0;
							//tolerance <- 0.0;
							weightShops <- 0.9;
							weightTour <- 0.0;
							weightHoreca <- 0.4;
							weightCult <- 0.2;
							lanes_attribute <- "nbLanes";
							//obstacle_species <- [species(self)];
							//do Choose_Target;
							timebudget <- gauss(6351, 3585);
							do Which_Road;
							if flip (1) {numberregionalvisitors <-  numberregionalvisitors +1;}
							else {numberregionalvisitors}
						}

					}

				}
				match_between [9407,10000] {
					if (numberothervisitors < 12) {
						create othervisitor number: 1 {
							starttime <- time;
							speed <- 0.5;
							//target <- any_location_in(one_of(poi));
							//start <- one_of(source);
							type <- 3;
							location <- source(1);
							startlocation <-location;
							//living_space <- 0.0;
							//tolerance <- 0.0;
							weightShops <- 0.4;
							weightTour <- 0.9;
							weightHoreca <- 0.2;
							weightCult <- 0.1;
							lanes_attribute <- "nbLanes";
							//obstacle_species <- [species(self)];
							//do Choose_Target;
							timebudget <- gauss(8136, 5365);
							do Which_Road;
							if flip (1) {numberothervisitors <-  numberothervisitors +1;}
							else {numberothervisitors}
						}

					}

				}
				}
				//numberReleasedPedestrians <-  numberReleasedPedestrians +1;
			}
		}					
				aspect base{
					//draw parking_icon size: 30 ;
					//file: parking image: parking_icon.gif;
					draw circle (6) color: rgb("black");
				}
			}
			
	
	
	// points of attraction 
	species poi {
		int id;
		//string description <- nil;
		//float attractiveness <-  rnd(1000)/1000;
		//bool visited <- false;
		aspect base {    
			draw shape color: rgb("white") ;
		} 
	}
	
	species myFollowedRoad{
		road myRoad <- nil;
		float myRoadgewicht <- nil;
		int myRoadtimesFollowed <- 0;
		
		
		
	}
	
	species people skills: [driving]  { 
		int starttime;
		float speed; 
		int type <- 0;
		rgb color <- rgb(rnd(255),rnd(255),rnd(255)) ;
		point target <- nil ; 
		point startlocation <-nil;
		list<myFollowedRoad> followedRoads;
		road roadJustVisited <- nil;
		road roadToFollow <- nil;
		point pointToGoTo <- nil;
		float distanceWalked <- 0.0;
		float weightShops <- 0.0;
		float weightTour <- 0.0;
		float weightHoreca <- 0.0;
		float weightCult <- 0.0;
		int timebudget;
		int nb_inhabitant <- 0;
		int nb_regionalvisitor <- 0;
		int nb_othervisitor <- 0;
		const walking_man type: file <- file("../images/long_steps.png") ;
//beschikbare tijd (nu getrokken uit een normale distributie maar kan ook anders
		
		
		//this reflex is executed only when normalMove = true
			reflex move when:time <= timebudget {
		//reflex move when:((time - starttime) <= timebudget) {
			//copy location to variable previouslocation
			//previousLoc <- copy(location);
			//calculate route and move to target
			//do Which_Road;
			bool roadNotFollowed <- true;
			do goto_driving target: pointToGoTo on: the_graph speed: speed ;
			switch location { 
				match pointToGoTo {		
					//de zojuist gevolgde weg in roadJustVisited zetten
					roadJustVisited <- roadToFollow;
					// de afstand bijhouden voor de agent.
					distanceWalked <- distanceWalked + roadJustVisited.shape.perimeter;
					//het geheugen bijwerken
					loop fr over: followedRoads{
						ask fr{
							if myRoad = myself.roadJustVisited {
								myRoadtimesFollowed <- myRoadtimesFollowed +1;
								if myRoadtimesFollowed > 1 {roadNotFollowed <- false;}
							}
						}
					}
					
//					if length(followedRoads)  > numberOfRoadsInMemory{
//						myFollowedRoad RoadtoRemove <- followedRoads[0];
//						remove all: RoadtoRemove from: RoadtoRemove;
//						write "removed old road from memory";
//					}
					
					//tellertje voor de betreffende weg bijhouden voor het aantal pedestrians dat 
					//over deze weg is gelopen
					roadJustVisited.nrOfPassedPedestrians <- roadJustVisited.nrOfPassedPedestrians + 1;
					if (roadNotFollowed= true){
					switch type{
						match 1{roadJustVisited.nrOfPassedInhabitants <- roadJustVisited.nrOfPassedInhabitants + 1;}
						match 2{roadJustVisited.nrOfPassedRegionalVisitors <- roadJustVisited.nrOfPassedRegionalVisitors +1;}
						match 3{roadJustVisited.nrOfotherVisitors <- roadJustVisited.nrOfotherVisitors + 1;}	
						}
					}
					else{
						switch type{
						match 1 {roadJustVisited.nrOftotalPassedInhabitants <- roadJustVisited.nrOftotalPassedInhabitants +1;}
						match 2{roadJustVisited.nrOftotalPassedRegionalVisitors <- roadJustVisited.nrOftotalPassedRegionalVisitors +1;}
						match 3{roadJustVisited.nrOftotalPassedotherVisitors <- roadJustVisited.nrOftotalPassedotherVisitors + 1;}
			}
			}
					// de roadToFollow even op nil zetten
					roadToFollow <- nil;
					
					//nu weer een nieuwe weg kiezen
					do Which_Road; 	
				}
			}
		}
		
		//Als de tijd op is neem kortste weg naar parkeergarage
		//reflex goback when: (time - starttime) > timebudget {
		reflex goback when: time > timebudget	{
			color <- rgb('red');
			do goto_driving target: startlocation on: the_graph speed: speed ;
			if location = startlocation {
				//commit harakiri
				//do die;
			}	
		}	
		
		
		action Which_Road{
				list<road> potentialRoads <- nil;
				float gewicht <- 0.0;
				float gewichtMax <- 0.0;
				float partweight <- 0.0;
				map gewichtRoadCombie <- nil;
				
				//vind de kruizing dichts bij de locatie van de agent
				// de pois zijn de kruisingen
				target <- poi closest_to(self);
							
				//vind de wegen die aan deze kruising gekoppeld zijn en 
				//stop ze in de potentialRoads lijst (behalve als ze net bezocht zijn)
				loop pr over: the_graph in_edges_of(target){
					if pr != roadJustVisited{
						 add pr to: potentialRoads;
					}
				}
				loop pr over: the_graph out_edges_of(target){
					if pr != roadJustVisited{
						 add pr to: potentialRoads;
					}
				}
				
				//Eerst kijken of er meer dan 1 weg aan de kruising zit. Als dit niet zo is dan is er
				//sprake van een doodlopende weg en moeten we wat anders doen
				if length(potentialRoads) > 1{
					//even wat info op de console
					write "Possible roads for agent "+self.name+" :";
					ask potentialRoads {
						bool notWalked <- true;								
						loop fr over: myself.followedRoads{
							ask fr{
								if myself = myRoad{
									myRoadgewicht <- myRoadgewicht * followedRoadMemoryDecay;
									gewicht <- myRoadgewicht;
									write "##########: "+myRoadgewicht;
									notWalked <- false;
								}
							}
						}
						if notWalked{
							partweight <- ((at_shop*myself.weightShops)+(at_tourist*myself.weightTour)+(at_horeca*myself.weightHoreca)+(at_cult*myself.weightCult));
							
							
							if myself.type = 1 {
								if partweight < 0.002{
									gewicht <- partweight + (inh_zone_attr*0.05);
								}
								else {
								gewicht <- partweight * inh_zone_attr;}
							}
							if myself.type = 2 {
								if partweight < 0.002{
									gewicht <- partweight + (reg_zone_attr * 0.05);
								}
								else{
								gewicht <- partweight * reg_zone_attr;}
							}
							if myself.type = 3 {
								if partweight < 0.002{
									gewicht <- partweight + (nonr_zone_attr * 0.05);
								}
								else{
								gewicht <- partweight * nonr_zone_attr;}
							}
						}
					
						write "		id: "+name+", weight: "+gewicht;
						//tijdelijk map om de combinatie weg en gewicht te kunnen opslaan
						//gebruikt om hierna een weg eruit te kunnen selecteren op basis van 
						//probability.
						add self at: gewicht to: gewichtRoadCombie;
					}
					
					
					bool doStochastic <- true;
					float maxWeight <- nil;
					maxWeight <- gewichtRoadCombie.pairs max_of (each.key);
					if  maxWeight < 0.001{
						doStochastic <- false;
					}
					
					if doStochastic {
					loop while: (roadToFollow = nil){
						loop p over: gewichtRoadCombie.pairs  {
								float gew <- p.key;
								//write "flipperdeflip";
								if flip(gew){
									bool newRoad <- true;
									roadToFollow <- p.value;
									if length(followedRoads) > 0{
										loop fr over: followedRoads{
											ask fr{
												if myRoad = myself.roadToFollow {
													newRoad <- false;
												}
											}
										}						
									}
									
								if newRoad{
									create myFollowedRoad number: 1 returns:  mfr{
										myRoad <- myself.roadToFollow;
										myRoadgewicht <- gew;
									}
									add mfr to: followedRoads;
								}
							}
						}
					}
				}
				else{
					// schakel in deterministische mode
					// ik heb hier gekozen om een willekeurig weg te kiezen aangezien 
					// de attracties extreem klein zijn
					write "Attraction to low to choose: entering deterministic mode";
					bool newRoad <- true;
					roadToFollow <- one_of (gewichtRoadCombie);
					if length(followedRoads) > 0{
						loop fr over: followedRoads{
							ask fr{
								if myRoad = myself.roadToFollow {
									newRoad <- false;
								}
							}
						}						
					}
									
					if newRoad{
						create myFollowedRoad number: 1 returns:  mfr{
							myRoad <- myself.roadToFollow;
							myRoadgewicht <- 0.001;
						}
						add mfr to: followedRoads;
					}
				}
			}						
				//oops we zaten in een doorlopende weg. We maken de roadToFollow de roadJustVisited zodat
				// we hierover terug kunnen
				else{
						write "Cannot make decision (perhaps dead-end): returning";
						roadToFollow <- roadJustVisited;	
					}
				
				
				write "chosen road:"+roadToFollow.name;
				write "----------------------------------------------------------------";
				
				//We zoeken het eind van de weg ten opzicht van het punt waar de pedestrian agent nu staat

				//Eerst het weg segment converteren naar een path
				path pathToFollow <- path(roadToFollow.shape.points);
				
				//begin en eind van het path opvragen
				point p1 <-  pathToFollow.source;
				point p2 <-  pathToFollow.target;
					
				// ik weet niet van te voren welk op punt (p1 of p2) de agent nu staat. Dat moet ik
				//wel weten om pointToGoTo te zetten. 
				if p1 = target 
				{
					pointToGoTo <- p2;
				}				
				else{
					pointToGoTo <- p1;
						
				}
			}
			
				
		
		//visualisation of the pedestrians (currently black circles with diameter 1)
		aspect base {
			draw circle(2) color: rgb("black") ;
		}
	}
	

	species inhabitant parent: people {
			aspect base {
				//draw walking_man size: 15 color: rgb("red") ;
				draw circle(6) color: rgb("red");
			}

		}

	species regionalvisitor parent: people {
			aspect base {
				//draw walking_man size: 15 color: rgb (0,153,51) ;//draw circle(6) color: rgb("green");
				draw circle(6) color: rgb("green");
				
			}

		}

	species othervisitor parent: people {
			aspect base {
				//draw walking_man size:15  color: rgb ("blue");//draw circle(6) color: rgb("blue");
				draw circle(6) color: rgb("blue");
				
			}

		}
		
	}
 

experiment delft_pedestrian_movement type: gui {
	parameter "Probability of agent creation:" var: probabilityOfCreation category: "Control Parameters";
	//parameter "Number of roads to keep in memory:" var: numberOfRoadsInMemory category: "Control Parameters";
	//parameter "Lower weight after road visited:" var: followedRoadMemory category: "Control Parameters";	
	parameter "weight shops:" var: A category: "Attraction functions for inhabitants (red)";
	parameter "weight tourist att.:" var: B category: "Attraction functions for inhabitants (red)";
	parameter "weight drinking/dining:" var: C category: "Attraction functions for inhabitants (red)";
	parameter "weight cultural att.:" var: D category: "Attraction functions for inhabitants (red)";
	parameter "weight shops:" var: E category: "Attraction functions for visitors within region (green)";
	parameter "weight tourist att.:" var: F category: "Attraction functions for visitors within region (green)";
	parameter " weight drinking/dining:" var: G category: "Attraction functions for visitors within region (green)";
	parameter " weight cultural att.:" var: H category: "Attraction functions for visitors within region (green)";
	parameter " weight shops:" var: I category: "Attraction functions for visitors outside region (blue)";
	parameter " weight tourist att.:" var: J category: "Attraction functions for visitors outside region (blue)";
	parameter " weight drinking/dining:" var: K category: "Attraction functions for visitors outside region (blue)";
	parameter " weight cultural att.:" var: L category: "Attraction functions for visitors outside region (blue)";
	
		user_command save_density_shape {
		write "start writing shapefiles...";
      	save road to: "../results/unique_and_total_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [Oid::"roadID", nrOfPassedInhabitants::"Inhabitants", nrOftotalPassedInhabitants::"totInhab", nrOfPassedRegionalVisitors::"RegVisit", nrOftotalPassedRegionalVisitors::"totReg", nrOfotherVisitors::"otherVisit",  nrOftotalPassedotherVisitors::"totOther"];
      	
      	/*save road to: "../results/inhabitants_total_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOftotalPassedInhabitants::"totInhab"];
        save road to: "../results/regionalvisitors_total_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOftotalPassedRegionalVisitors::"totReg"];
        save road to: "../results/othervisitors_total_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOftotalPassedotherVisitors::"totOther"];
        save road to: "../results/totalpedest_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOfPassedPedestrians::"totalPassed"];
        save road to: "../results/inhabitant_destdensity_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOfPassedInhabitants::"Inhabitants"];
        save road to: "../results/regvisitors_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOfPassedRegionalVisitors::"RegVisit"];
        save road to: "../results/othervistor_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOfotherVisitors::"otherVisit"];        
        */
        write "shapefiles written to disk";
        
        
   }
   
        user_command WriteDistance{
              write "start writing file...";
             ask inhabitant{
                    write "writing: "+ name;
                    save [name, distanceWalked] to: "../results/distances/walkeddistances"+cycle+".csv" type: "csv";
             }
             ask regionalvisitor{
                    write "writing: "+ name;
                    save [name, distanceWalked] to: "../results/distances/walkeddistances"+cycle+".csv" type: "csv";
             }
             ask othervisitor{
                    write "writing: "+ name;
                    save [name, distanceWalked] to: "../results/distances/walkeddistances"+cycle+".csv" type: "csv";
             }
             
             write "..done writing file";
   	}
       
  
	output {
		
		monitor "total number of inhabitants" value: numberinhabitants;
		monitor "number of inhabitants in city"value: nb_inhabitant;
		monitor "total number of regional visitors" value: numberregionalvisitors;
		monitor "number of regional visitors in city" value: nb_regionalvisitor;
		monitor "total number of visitors from outside region"value: numberothervisitors;
		monitor "number of visitors from outside region in city" value: nb_othervisitor;
		monitor "total number of people" value: numberReleasedPedestrians;
		monitor "total number of people in city" value: total;						
		display delft_display refresh_every: 1 { 
			
			image background file:"../images/background4.jpg";
			 graphics "dead end" {
				loop vertex over: the_graph.vertices {
					if (the_graph degree_of vertex < 2) {
						draw circle(10) at: point(vertex) color: rgb("red");
					}
				}
			}
			species road aspect: base;
			species myFollowedRoad;
			species people aspect: base;
			species inhabitant aspect: base;
			species regionalvisitor aspect: base;
			species othervisitor aspect: base;
			species source aspect: base;
			//species poi aspect: base;
		} 
		//monitor nbGoalsAchived value: nbGoalsAchived refresh_every: 1;
		//monitor nr_of_pedestrians value: length(people) refresh_every: 1;
	}

} 	 

experiment 'Batch runs' type: batch repeat: 2 keep_seed: true until: ( time = 20000 ) {
	
	parameter "Bach run name:" var: runName category: "General parameters";
	parameter "weight shops:" var: A category: "Attraction functions for inhabitants (red)";
	parameter "weight tourist att.:" var: B category: "Attraction functions for inhabitants (red)";
	parameter "weight drinking/dining:" var: C category: "Attraction functions for inhabitants (red)";
	parameter "weight cultural att.:" var: D category: "Attraction functions for inhabitants (red)";
	parameter "weight shops:" var: E category: "Attraction functions for visitors within region (green)";
	parameter "weight tourist att.:" var: F category: "Attraction functions for visitors within region (green)";
	parameter " weight drinking/dining:" var: G category: "Attraction functions for visitors within region (green)";
	parameter " weight cultural att.:" var: H category: "Attraction functions for visitors within region (green)";
	parameter " weight shops:" var: I category: "Attraction functions for visitors outside region (blue)";
	parameter " weight tourist att.:" var: J category: "Attraction functions for visitors outside region (blue)";
	parameter " weight drinking/dining:" var: K category: "Attraction functions for visitors outside region (blue)";
	parameter " weight cultural att.:" var: L category: "Attraction functions for visitors outside region (blue)";
	
	
	parameter "inh sensitivity shops" var: A  among: [0.4];//[0.4, 0.49, 0.5, 0.51, 0.6];
	method exhaustive minimize: A;
	int cpt <- 0;
	action _step_ {

		write "start writing shapefiles for desities..." + cpt;
      	//save road to: "../results/"+runName+"_unique_and_total_density_"+cpt+".shp" with: [Oid::"roadID", nrOfPassedInhabitants::"Inhabitants", nrOftotalPassedInhabitants::"totInhab", nrOfPassedRegionalVisitors::"RegVisit", nrOftotalPassedRegionalVisitors::"totReg", nrOfotherVisitors::"otherVisit",  nrOftotalPassedotherVisitors::"totOther"];
		ask road{
      	save [Oid, nrOfPassedInhabitants, nrOftotalPassedInhabitants, nrOfPassedRegionalVisitors, nrOftotalPassedRegionalVisitors, nrOfotherVisitors, nrOftotalPassedotherVisitors] to: "../results/"+runName+"_unique_and_total_density_"+myself.cpt+".csv" type: csv;
      	}   	
      	/*save road to: "../results/inhabitants_total_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOftotalPassedInhabitants::"totInhab"];
        save road to: "../results/regionalvisitors_total_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOftotalPassedRegionalVisitors::"totReg"];
        save road to: "../results/othervisitors_total_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOftotalPassedotherVisitors::"totOther"];
        save road to: "../results/totalpedest_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOfPassedPedestrians::"totalPassed"];
        save road to: "../results/inhabitant_destdensity_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOfPassedInhabitants::"Inhabitants"];
        save road to: "../results/regvisitors_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOfPassedRegionalVisitors::"RegVisit"];
        save road to: "../results/othervistor_density_"+cycle+"_"+machine_time+".shp" type: "shp" with: [nrOfotherVisitors::"otherVisit"];        
        */
       
        write "shapefiles written to disk";
        write "start writing file for distances...";
             ask inhabitant{
                    write "writing: "+ name;
                    save [name, distanceWalked] to: "../results/distances/"+runName+"_walkeddistances_"+myself.cpt+".csv" type: "csv";
             }
             ask regionalvisitor{
                    write "writing: "+ name;
                    save [name, distanceWalked] to: "../results/distances/"+runName+"_walkeddistances_"+myself.cpt+".csv" type: "csv";
             }
             ask othervisitor{
                    write "writing: "+ name;
                    save [name, distanceWalked] to: "../results/distances/"+runName+"_walkeddistances_"+myself.cpt+".csv" type: "csv";
             }
             
             write "..done writing file";
		cpt <- cpt + 1;
	}

}


	




