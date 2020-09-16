({
	obtainProducts : function(component, helper){
		var action = component.get("c.getProducts");
		action.setParams({ accountId : component.get("v.recordId")}); 
        action.setCallback(this, function(response) {
			debugger;
            var state = response.getState();
            if (state === "SUCCESS") {
                response = JSON.parse(response.getReturnValue());
                if (response.success) {

					component.set("v.dataForCustomTable", response.result);
					component.set("v.sortedData", response.result);
					component.set("v.isLoaded", true);
				}
            }
        });
        
        $A.enqueueAction(action);
	},
	sortProducts : function(component){
		debugger;
		let searchString = component.get("v.searchString");
		let productList = component.get("v.dataForCustomTable");

		if(searchString==""){
			component.set("v.sortedData", productList);
			setTimeout($A.getCallback(() => component.set("v.isLoaded", true)), 1);
			return;
		}
		let sortedProducts = productList.filter((line)=>{
			
			let isSuit = false;

				debugger;
				if(line.lines[0].label=="name" && line.lines[0].value.includes(searchString)){
					isSuit = true;
				}
				if(line.lines[1].label=="sku" && line.lines[1].value.includes(searchString)){
					isSuit = true;
				}
				if(line.lines[2].label=="invetory" && line.lines[2].value == searchString){
					isSuit = true;
				}

			return isSuit;
		});
		setTimeout($A.getCallback(() => component.set("v.isLoaded", true)), 1);
		component.set("v.sortedData", sortedProducts);
	}
})