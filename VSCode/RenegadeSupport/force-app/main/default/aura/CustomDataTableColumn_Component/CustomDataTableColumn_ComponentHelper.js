({
  updateDom: function(c, h) {
    console.log(c.get("v.value"));
    let type = c.get("v.type");
    if (
      type == "string" &&
      !!c.get("v.value") &&
      c.get("v.value").includes("<img") &&
      !c.get("v.value").includes("title")
    ) {
      let valList = c.get("v.value").split("<img ");
      if (!valList.length) return;
      valList.forEach((val, index, arr) => {
        if (val != "") {
          var title = val.slice(val.indexOf('alt="') + 5);
          title = 'title="' + title.split('"')[0] + '" ';
          arr[index] = "<img " + title + val;
        }
      });
      valList = valList.join("");
      console.log(valList);
      c.set("v.value", valList);
    }
  }
});