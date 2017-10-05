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
	//load network shapefile (shp should contain atrributes:  nr_lans","weight" and "wegtype"
	// the weight in the current Delft network shape are all set to 1 so not influence to be expecte
	// need to try out to see how and what the effects of weights are
	file shape_file_roads  <- file("../includes/wegendelft_final.shp") ;


	//load shapefile with starting points of pedestrians (points)
	file shape_file_sources <- file("../includes/parking.shp") ;

	// load shape_file with pois. At this moment pois are represented as points. However in principle this could 
	// also be polygons are linear segments such as parts of a road. An agent should than choose a arbitrary point somewhere
	// in the polygon or along the linear segement.
	file shape_file_pois <- file("../includes/kruizingendelft_final.shp") ;

	//load shape_file with boundingbox of the network shapefile
	
	file shape_file_bounds <- file("../includes/centrum_boundaries.shp") ;

	//parameter to set the # of agents. Can be change also via the gui
	int capacity <- 10;
	
	//distance to search for pois. Can be changed also via the gui
	int distance <- 500;
	
	//set the extend of the geometry
	geometry shape <- envelope(shape_file_bounds);
	
	// initialize a counter to keep track on the nr of pois reached by the agents
	int nbGoalsAchived <- 0;
	
	//intialize a variable of type graph wich contain later the network
	graph the_graph;  	
	
	// parameter which determine the probability a new pedestrion is created at the start location.
	float probabilityOfCreation <- 0.5;
	
	//counter for the number of released pedestrian in the simulation;
	int numberReleasedPedestrians <- 0; 
	
	//parameter that determines the number of traveled roads it can keep in memory
	int numberOfRoadsInMemory <- 10;
	
	//parameter for the shopping time
	int timeBudget <-1200;
	
	//parameter for the deviation in shopping time
	int timeDeviation <- 500;

	 
	init {  

		//create road species by from the network shapefile an load the attribute names into corresponding attribute of the road species
		
 
		create road from: shape_file_roads with:[name::string(read("STT_NAAM")),nbLanes::int(read("nr_lanes")),wegtype::int(read("at_links_1")),at_shop::float(read("shops_1")), at_tourist::float(read("tourist_1")), at_horeca::float(read("horeca_1"))]{} 	
 
		//create source species from the shapefile with startign points
		create source from: shape_file_sources with:[id::int(read("id"))] ;	
		//create pois species from the shapefile with pois
		create poi from: shape_file_pois with:[id::int(read("WVK_ID"))];
		
		//way of assigning weights to the road segments. Simple factor * lenght. Alternatively use weight variable of road to
		//set dynamically the factor
		map<road,float> weights_map <- road as_map (each:: (1 * each.shape.perimeter));
		the_graph <-  (as_edge_graph(road)) with_weights weights_map; 						
	}
	
}
 
entities {
	species road {
		int nbLanes;
		int wegtype;
		string name;
		float  weight;
		int substractedWeight <- nil;
		int indexDirection;
		path geom_visu;
		rgb color <- rgb("gray");
		int nrOfPassedPedestrians <- 0;
		float at_shop;
		float at_tourist;
		float at_horeca;

		
		init{
			
			if at_shop = 0 {at_shop <- 0.001;}
			if at_tourist = 0 {at_tourist <- 0.001;}
			if at_horeca = 0 {at_horeca <- 0.001;}
		}
		
		aspect base {
			draw shape color: rgb('blue');
		}

	}
	
	species source {
		int id;
		//int capacity <- 10; //slowly release of pedestrians from the parking: 1 at every tick till capacity is reached
 		
 		
		reflex release_pedestrian when: (numberReleasedPedestrians < capacity) {
			if flip (probabilityOfCreation){
			int kans <- rnd(100);
			switch kans {
				match_between [1, 30] {
					if (length(tourist) < capacity) {
						create tourist number: 1 {
							speed <- 4;
							//target <- any_location_in(one_of(poi));
							//start <- one_of(source);
							location <- one_of(source);
							startlocation <-location;
							living_space <- 0.0;
							tolerance <- 0.0;
							weightShops <- 0.5;
							weightTour <- 0.9;
							weightHoreca <- 0.2;
							lanes_attribute <- "nbLanes";
							obstacle_species <- [species(self)];
							//do Choose_Target;
							do Which_Road;
						}

					}

				}

					match_between [31, 50] {
						if ((length(shopper)) < capacity) {
							create shopper number: 1 {
								speed <- 8;
								//target <- any_location_in(one_of(poi));
								//start <- one_of(source);
								location <- one_of(source);
								living_space <- 0;
								tolerance <- 0;
								weightShops <- 0.9;
								weightTour <- 0.0;
								weightHoreca <- 0.2;
								startlocation <-location;
								lanes_attribute <- "nbLanes";
								obstacle_species <- [species(self)];
								//do Choose_Target;
								do Which_Road;
							}

						}	

					}
				match_between [51, 100] {
						if ((length(leisure)) < capacity) {
							create leisure number: 1 {
								speed <- 1;
								//target <- any_location_in(one_of(poi));
								//start <- one_of(source);
								location <- one_of(source);
								living_space <- 0;
								tolerance <- 0;
								weightShops <- 0.5;
								weightTour <- 0.5;
								weightHoreca <- 0.5;
								startlocation <- location;
								lanes_attribute <- "nbLanes";
								obstacle_species <- [species(self)];
								//do Choose_Target;
								do Which_Road;
							}

						}
					}
				}
				numberReleasedPedestrians <-  numberReleasedPedestrians +1;
			}
		}					
				aspect base {
					draw circle (6) color: rgb("black");
				}
			}
			
	
	
	// points of attraction 
	species poi {
		int id;
		string description <- nil;
		float attractiveness <-  rnd(1000)/1000;
		bool visited <- false;
		aspect base {    
			draw shape color: rgb("green") ;
		} 
	}
	
	
	species people skills: [driving]  { 
		float speed; 
		//int welkeweg <- 0;
		rgb color <- rgb(rnd(255),rnd(255),rnd(255)) ;
		//list<poi> potential_Targets <- nil;
		//poi target_poi;
		point target <- nil ; 
		point startlocation <-nil;
		//point targetBis <- nil ; 
		point previousLoc <- nil;
		bool return_path <- false;
		float evadeDist <- 300.0;
		//source start <- nil;
		float distance_to_source <- 0.0;
		road roadJustVisited <- nil;
		list<road> followedRoads;
		road roadToFollow <- nil;
		point pointToGoTo <- nil;
		float distanceWalked <- 0.0;
		float weightShops <- 0.0;
		float weightTour <- 0.0;
		float weightHoreca <- 0.0;
		

		//beschikbare tijd (nu getrokken uit een normale distributie maar kan ook anders
		int timebudget <- gauss(timeBudget,timeDeviation);
		
		//this reflex is executed only when normalMove = true
		reflex move when:time <= timebudget {
			//copy location to variable previouslocation
			//previousLoc <- copy(location);
			//calculate route and move to target
			//do Which_Road;
			do goto_driving target: pointToGoTo on: the_graph speed: speed ;
			switch location { 
				match pointToGoTo {
					
					//de zojuist gevolgde weg in roadJustVisited zetten
					roadJustVisited <- roadToFollow;
					// de afstand bijhouden voor de agent.
					distanceWalked <- distanceWalked + roadJustVisited.shape.perimeter;
					
					//het geheugen bijwerken
					write "Added road to memory";
					add roadJustVisited to: followedRoads;
					if length(followedRoads)  > numberOfRoadsInMemory{
						remove index: 0 from: followedRoads;
						write "Faded old road from memory";
					}
					
					//tellertje voor de betreffende weg bijhouden voor het aantal pedestrians dat 
					//over deze weg is gelopen
					roadJustVisited.nrOfPassedPedestrians <- roadJustVisited.nrOfPassedPedestrians + 1;
					
					// de roadToFollow even op nil zetten (strikt genomen waarschijnlijk niet nodig
					roadToFollow <- nil;
					
					//nu weer een nieuwe weg kiezen
					write pointToGoTo;
					do Which_Road; 	
				}
			}
		}
		
		//Als de tijd op is neem kortste weg naar parkeergarage
		reflex goback when: time > timebudget	{
			color <- rgb('red');
			do goto_driving target: startlocation on: the_graph speed: speed ;
			if location = startlocation {
				//commit harakiri
				do die;
			}	
		}	
		
		
		action Which_Road{
				list<road> potentialRoads <- nil;
				//vind de kruizing dichts bij de locatie van de agent
				// de pois zijn de kruisingen
				target <- poi closest_to(self);
				//write "Arrived at crossing: "+target.id;
				
				//vind de wegen die aan deze kruising gekoppeld zijn en 
				//stop ze in de potentialRoads lijst (behalve als ze al bezocht zijn)
				
				loop pr over: the_graph in_edges_of(target){
					bool notFollowed <- true;
					loop fr over: followedRoads{
						if pr = fr{
							notFollowed <- false;
						}
					}
					if notFollowed{
						add pr to: potentialRoads;
					}		 	
				}
				
				loop pr over: the_graph out_edges_of(target){
					bool notFollowed <- true;
					loop fr over: followedRoads{
						if pr = fr{
							notFollowed <- false;
						}
					}
					if notFollowed{
						add pr to: potentialRoads;
					}		 	
				}
				

				
				//Eerst kijken of er meer dan 1 weg aan de kruising zit. Als dit niet zo is dan is er
				//sprake van een doodlopende weg en moeten we wat anders doen
				if length(potentialRoads) > 0{
				
					//sorteer de wegen op basis van weight (hoogste weight eerst)
					//list potentialRoadsSorted <- potentialRoads sort_by (road(each).weight);				

					//even wat info op de console
					write "Mogelijke wegen voor agent "+self.name+" :";
					ask potentialRoads {
						//bereken het gewicht wat een agent aan een weg toekent op basis van de attractiewaarde (opgeslagen in het wegennetwerk)
						//en het belangs (gewicht) wat de agent toekent aan winkels, toeristattracties en horeca.
						weight <- ((at_shop*myself.weightShops)+(at_tourist*myself.weightTour)+(at_horeca*myself.weightHoreca));
						write "		id: "+name+", weight: "+weight;
					}
				
					// misschien hier nog wat over nadenken. Kan denk ik nog wat anders.
					loop while: (roadToFollow = nil){
						ask potentialRoads{
							if flip(weight){
								 // ik moet "myself" gebruik op te refereren aan de people agent want self is nu de road agent
								 // omdat we in een ask loop zitten waarin we de potential road uitvragen
								 myself.roadToFollow <- self;
							}
						}
					
					}
				}
					
				//oops we zaten in een doorlopende weg of alle richtingen waren al eens bezocht. We maken de roadToFollow de roadJustVisited zodat
				// we hierover terug kunnen
				else{
						write "Cannot make decision (perhaps dead-end): returning";
						roadToFollow <- roadJustVisited;	
					}
				
				
				write "gekozen weg:"+roadToFollow.name+" weight: "+roadToFollow.weight;
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
	
	
	species tourist parent: people {
			aspect base {
				draw circle(6) color: rgb("red");
			}

		}

	species shopper parent: people {
			aspect base {
				draw circle(6) color: rgb("green");
			}

		}

	species leisure parent: people {
			aspect base {
				draw circle(6) color: rgb("blue");
			}

		}
		
	}
 

experiment delft_pedestrian_movement type: gui {
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS";
	parameter "Shapefile for the sources:" var: shape_file_sources category: "GIS";
	parameter "Total number of pedestrian:" var: capacity category: "Control Parameters";
	parameter "Number of roads to keep in memory:" var: numberOfRoadsInMemory category: "Control Parameters";	
	parameter "Average Shopping time (seconds):" var: timeBudget category: "Control Parameters";	
	parameter "Standard deviation in shopping time (seconds):" var: timeDeviation category: "Control Parameters";		
	parameter "Shapefile for the crossings:" var: shape_file_pois category: "GIS";
	output {
		display delft_display refresh_every: 1 { 
			species road aspect: base;
			species people aspect: base;
			species tourist aspect: base;
			species shopper aspect: base;
			species leisure aspect: base;
			species source aspect: base;
			species poi aspect: base;
		}
		monitor nbGoalsAchived value: nbGoalsAchived refresh_every: 1;
		monitor nr_of_pedestrians value: length(people) refresh_every: 1;
	}

}







