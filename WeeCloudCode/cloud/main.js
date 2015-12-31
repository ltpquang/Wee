
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});

Parse.Cloud.beforeSave("MasterDevice", function(request, response) {

	var query = new Parse.Query("MasterDevice");
	query.equalTo("user", request.object.get("user"));
	query.equalTo("deviceIdentifier", request.object.get("deviceIdentifier"));

	query.first({
      success: function(object) {
      	console.log(object);
      	if (typeof object === 'undefined' || object.objectId === request.object.objectId) {
      		response.success();
      	}
        else if (object) {
          	response.error("record exists");
        } else {
          	response.success();
        }
      },
      error: function(error) {
        response.error("Could not validate uniqueness for this MasterDevice object.");
      }
    });
});
