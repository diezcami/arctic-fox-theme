// Pick a photo of the day
// mod how many pictures I currently have on this server.
  var date = new Date()
  var num = (date.getDay() * date.getYear() * date.getMonth()) % 119
  var photo = "../assets/cinnamon/" + num + ".jpg"
  document.getElementById("cinnaImage").src = photo;
