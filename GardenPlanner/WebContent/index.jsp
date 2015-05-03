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
static String hardinessZone="1";
static String sunPref="part sun";
static String harvestDur="1";

private static void findPlant() {
	String q = "PREFIX garden: <"+rel+"> " +
		  	"SELECT ?Plant ?Family "+
		  	"WHERE {" +
		  	"?Plant garden:hardinessZoneMin \""+hardinessZone+"\" ."+
		  	"?Plant garden:harvestDurationMax \""+harvestDur+"\" ."+
		  	"?Plant garden:inFamily ?Family ."+
		  	"?Family garden:sunMin \""+sunPref+"\" ."+
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
<br>
<h3>Find a plant for your garden:</h3>
  <form method="get">
  	<p class="subheading">Minimum hardiness zone:</p>
  	<select name="hardinessZone">
	  <option value="2">2</option>
	  <option value="3">3</option>
	  <option value="4">4</option>
	  <option value="8" selected>8</option>
	</select>
    <p class="subheading">Sun preference:</p>
    <input type="radio" name="sunPref" value="part shade">part shade
    <input type="radio" name="sunPref" value="part sun" checked="checked">part sun
    <input type="radio" name="sunPref" value="full sun">full sun
    <p class="subheading">Harvest duration:</p>
    <select name="harvestDur">
	  <option value="1">1</option>
	  <option value="8" selected>8</option>
	  <option value="13">13</option>
	</select> weeks
 
    <input type="submit" name="find" class="btn" value="Search">
  </form>
 <div class="result">
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
		out.println("<h3>Best plants for the season:</h3><table border=1 cellpadding=5><tr><th>Plant</th><th>Family</th></tr>");
		while (results.hasNext()) {
		QuerySolution row= results.next();
		RDFNode plant= row.get("Plant");
		RDFNode family= row.get("Family");
		out.println("<tr><td style=\"min-width:80px\">"+plant.toString().replace("http://jacobnibu.info/garden/","")+"</td><td style=\"min-width:100px\">"+
				family.toString().replace("http://jacobnibu.info/garden/","")+"</td></tr>");
		}qexec.close();
		out.println("</table>");
		}
	}
%>
</div>
<p></p>
</body>
</html>