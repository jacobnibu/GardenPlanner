<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<%@ page
import = "org.apache.log4j.PropertyConfigurator,
com.hp.hpl.jena.query.*,
com.hp.hpl.jena.rdf.model.*,
com.hp.hpl.jena.reasoner.Reasoner,
com.hp.hpl.jena.reasoner.ReasonerRegistry,
com.hp.hpl.jena.tdb.TDBFactory,
com.hp.hpl.jena.util.FileManager"
%>
<%! static final String NS = "http://jacobnibu.info/ont/garden/";
static final String rel = "http://jacobnibu.info/ont/garden#";
static Model tdb;
static String owlFile = "../input/garden.owl";
static String dataFile = "../input/plants.rdf";
static String logFile = "logs/log4j.properties";
static InfModel infmodel;
static String directory = "tdb";
static ResultSet results;
static QueryExecution qexec;
static String hardinessZone;
static String sunPref;
static String harvestDur;

private static void findPlant() {
	String q = "PREFIX garden: <"+rel+"> " +
		  	"SELECT * "+
		  	"WHERE {" +
		  	"?a ?b \""+hardinessZone+"\""+
//		  	"?Plant garden:hardinessZoneMin "+hardinessZone+
		  	"     }";
	executeQuery(q);
}

private static void executeQuery(String q){
	Query query = QueryFactory.create(q);
	qexec = QueryExecutionFactory.create(query, tdb);
	results = qexec.execSelect();
	System.out.println("\nQuery executed successfully!");
}

/* Read ontology from filesystem and store it into database */
public static Model createDBModel(String directory, InfModel model) {

	// connect store to dataset
    Dataset dataset = TDBFactory.createDataset(directory);
    Model tdb = dataset.getDefaultModel();
    // add the model into the dataset
    tdb.add(model);
    return tdb;

}

// this method reads ontology file and RDF file from disk and creates an inference model
	private static InfModel createInfModel(){
		
		Model schema = FileManager.get().loadModel(owlFile);
		if (schema == null) {
		    throw new IllegalArgumentException( "File: " + owlFile + " not found");
		        }
		Model data = FileManager.get().loadModel(dataFile);
		if (data == null) {
		    throw new IllegalArgumentException( "File: " + dataFile + " not found");
		        }
		Reasoner reasoner = ReasonerRegistry.getOWLReasoner();
		reasoner = reasoner.bindSchema(schema);
		InfModel infmodel = ModelFactory.createInfModel(reasoner,data);
		System.out.println("\nInference model created successfully!");
		return infmodel;
		
	}
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<link rel="stylesheet" type="text/css" href="css/style.css" />
<title>Garden Planner</title>
</head>
<body class="gradient">
<%
PropertyConfigurator.configure(logFile);
infmodel = createInfModel();
tdb = createDBModel(directory,infmodel);
%>
<h1 id="maintitle">Garden Planner</h1>
<a href="inference.jsp" class="toplink">Inference demo</a>
<p class="intro">Garden Planner helps you choose the right plants for the season</p>
<h3>Find a plant for your garden:</h3>
  <form method="get">
  	<p class="subheading">Minimum hardiness zone:</p>
  	<select name="hardinessZone">
	  <option value="1">1</option>
	  <option value="2">2</option>
	  <option value="3">3</option>
	  <option value="4">4</option>
	  <option value="5">5</option>
	  <option value="6">6</option>
	  <option value="7">7</option>
	  <option value="8">8</option>
	  <option value="9">9</option>
	  <option value="10">10</option>
	  <option value="11">11</option>
	</select>
    <p class="subheading">Sun preference:</p>
    <input type="radio" name="sunPref" value="part shade">part shade
    <input type="radio" name="sunPref" value="part sun">part sun
    <input type="radio" name="sunPref" value="full sun">full sun
    <p class="subheading">Harvest duration:</p>
    <input type="radio" name="harvestDur" value="1">1 week
    <input type="radio" name="harvestDur" value="5">5-10 weeks
    <input type="radio" name="harvestDur" value="10">more than 10 weeks
    <input type="submit" name="find" class="btn" value="Search">
  </form>
 
  <% 
  
	String search = request.getParameter("find");
	if(search!=null && search.equals("Search")){
		hardinessZone = request.getParameter("hardinessZone");
	    sunPref = request.getParameter("sunPref");
	    harvestDur = request.getParameter("harvestDur");
 		findPlant();
		if(!results.hasNext()){
			out.println("<p class=\"alert\">No plants match your search... please try again!</p>");
		}else{
		out.println("<h3>Best plants for the season are:</h3>");
		while (results.hasNext()) {
		QuerySolution row= results.next();
		RDFNode thing= row.get("a");
		//Literal label= row.getLiteral("Sun_Preference_Min");
		out.println(thing.toString()+"<br>");
		}qexec.close();
		}
	}
%>
<p></p>
</body>
</html>