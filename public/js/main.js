function fetchTweets(snapshot) {
	var endpoint;

	if( !snapshot ) {
		endpoint = "/twitter/";
	} else {
		endpoint = "/snapshot.json";
	}

	$.get(endpoint, function(resp) {
		if( resp && resp.result && resp.result == "success" ) {
			newTweets(resp.tweets);
		}
	}, "json");
}

function newTweets(tweets) {
	for( var i = 0, len = tweets.length; i < len; i++ ) {
		//console.log( tweets[i] );
		
		var t;
		if( tweets[i].type == "tweet" ) {
			t = "<p class='tweet'>"+tweets[i].text+"</p>";
		} else if( tweets[i].type == "meta" ) {
			t = "<p class='tweet meta'>"+tweets[i].text+"</p>";
		} else if( tweets[i].type == "image" ) {
			t = "<p class='tweet image'>"+tweets[i].text+"</p>";
		} else if( tweets[i].type == "random" ) {
			t = "<p class='tweet random'>"+tweets[i].text+"</p>";
		}
		
		$("#tweets").append( t );
	}
}

$(window).load(function(){
	$("#wrapper").animate({
		opacity: 1
	});	
});

$(document).ready(function() {
	// true: load from snapshot.json
	// false: rebuild the data
	//fetchTweets(true);
	fetchTweets(false);
});