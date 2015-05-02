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

private static void queryPlantProperties() {
	String q = "PREFIX garden: <"+rel+"> " +
			"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> " +
		  	"SELECT distinct ?Properties_of_Plant "+
		  	"WHERE {" +
		  	"?Properties_of_Plant rdfs:domain garden:Plant"+
		  	"     }";
	executeQuery(q);
}


private static void queryPlantSunPreference() {
	String q = "PREFIX garden: <"+rel+"> " +
		  	"SELECT ?Plant ?Sun_Preference_Min "+
		  	"WHERE {" +
		  		"?Plant garden:inFamily ?Family ."+
		  		"?Family garden:sunMin ?Sun_Preference_Min ."+
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
<h1 id="maintitle">Garden Planner</h1>
<a href="index.jsp">Home</a>
<p>This page sends a SPARQL query to an inference model in persistent storage (TDB storage) and displays the results</p>
<form method="get">
<input type="submit" name="queryProperties" class="btn" value="Display plant properties">
<input type="submit" name="querySunPref" class="btn" value="Display sun preference ">
</form>
<%
PropertyConfigurator.configure(logFile);
infmodel = createInfModel();
tdb = createDBModel(directory,infmodel);

String queryProperties = request.getParameter("queryProperties");
if (queryProperties != null) {
	queryPlantProperties();
	out.println("<h3>Properties of plants (from RDF dataset)</h3>");
	while (results.hasNext()) {
	QuerySolution row= results.next();
	RDFNode thing= row.get("Properties_of_Plant");
	//Literal label= row.getLiteral("Sun_Preference_Min");
	out.println(thing.toString()+"<br>");
	}qexec.close();
}
String querySunPref = request.getParameter("querySunPref");
if (querySunPref != null) {	
	queryPlantSunPreference();
	out.println("<h3>Minimum sun preference of plants (inferred property)</h3>");
	while (results.hasNext()) {
    QuerySolution row= results.next();
    RDFNode thing= row.get("Plant");
    Literal label= row.getLiteral("Sun_Preference_Min");
    out.println(thing.toString()+" ... "+"<b><font color=\"blue\">"+label.getString()+"</font></b><br>");
	}qexec.close();
}
%>
</body>
</html>