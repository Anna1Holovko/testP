public with sharing class Utilities {
	
	public static string getStateinitial (string state){
		state = String.isNotBlank(state) ? state : '';
		String lowerState = state.toLowerCase();
		String stateInitial = '';
		switch on lowerState {
			when 'alabama'{
				stateInitial = 'AL'; 
			}
			when 'alaska'{
				stateInitial = 'AK'; 
			}
			when 'arizona'{
				stateInitial = 'AZ'; 
			}
			when 'arkansas'{
				stateInitial = 'AR'; 
			}
			when 'california'{
				stateInitial = 'CA'; 
			}
			when 'colorado'{
				stateInitial = 'CO'; 
			}
			when 'connecticut'{
				stateInitial = 'CT'; 
			}
			when 'delaware'{
				stateInitial = 'DE'; 
			}
			when 'florida'{
				stateInitial = 'FL'; 
			}
			when 'georgia'{
				stateInitial = 'GA'; 
			}
			when 'hawaii'{
				stateInitial = 'HI'; 
			}
			when 'idaho'{
				stateInitial = 'ID'; 
			}
			when 'illinois'{
				stateInitial = 'IL'; 
			}
			when 'indiana'{
				stateInitial = 'IN'; 
			}
			when 'iowa'{
				stateInitial = 'IA'; 
			}
			when 'kansas'{
				stateInitial = 'KS'; 
			}
			when 'kentucky'{
				stateInitial = 'KY'; 
			}
			when 'louisiana'{
				stateInitial = 'LA'; 
			}
			when 'maine'{
				stateInitial = 'ME'; 
			}
			when 'maryland'{
				stateInitial = 'MD'; 
			}
			when 'massachusetts'{
				stateInitial = 'MA'; 
			}
			when 'michigan'{
				stateInitial = 'MI'; 
			}
			when 'minnesota'{
				stateInitial = 'MN'; 
			}
			when 'mississippi'{
				stateInitial = 'MS'; 
			}
			when 'missouri'{
				stateInitial = 'MO'; 
			}
			when 'montana'{
				stateInitial = 'MO'; 
			}
			when 'nebraska'{
				stateInitial = 'NE'; 
			}
			when 'nevada'{
				stateInitial = 'NV'; 
			}
			when 'new hampshire'{
				stateInitial = 'NH'; 
			}
			when 'new jersey'{
				stateInitial = 'NJ'; 
			}
			when 'new mexico'{
				stateInitial = 'NM'; 
			}
			when 'new york'{
				stateInitial = 'NY'; 
			}
			when 'north carolina'{
				stateInitial = 'NC'; 
			}
			when 'north dakota'{
				stateInitial = 'ND'; 
			}
			when 'ohio'{
				stateInitial = 'OH'; 
			}
			when 'oklahoma'{
				stateInitial = 'OK'; 
			}
			when 'oregon'{
				stateInitial = 'OR'; 
			}
			when 'pennsylvania'{
				stateInitial = 'PA'; 
			}
			when 'rhode island'{
				stateInitial = 'RI'; 
			}
			when 'south carolina'{
				stateInitial = 'SC'; 
			}
			when 'south dakota'{
				stateInitial = 'SD'; 
			}
			when 'tennessee'{
				stateInitial = 'TN'; 
			}
			when 'texas'{
				stateInitial = 'TX'; 
			}
			when 'utah'{
				stateInitial = 'UT'; 
			}
			when 'vermont'{
				stateInitial = 'VT'; 
			}
			when 'virginia'{
				stateInitial = 'VA'; 
			}
			when 'washington'{
				stateInitial = 'WA'; 
			}
			when 'west virginia'{
				stateInitial = 'WV'; 
			}
			when 'wisconsin'{
				stateInitial = 'WI'; 
			}
			when 'wyoming'{
				stateInitial = 'WY'; 
			}
			when 'ontario'{
				stateInitial = 'ON'; 
			}
			when 'quebec'{
				stateInitial = 'QC'; 
			}
			when 'québec'{
				stateInitial = 'QC'; 
			}
			when 'british columbia'{
				stateInitial = 'BC'; 
			}
			when 'alberta'{
				stateInitial = 'AB'; 
			}
			when 'manitoba'{
				stateInitial = 'MB'; 
			}
			when 'saskatchewan'{
				stateInitial = 'SK'; 
			}
			when 'nova scotia'{
				stateInitial = 'NS'; 
			}
			when 'new brunswick'{
				stateInitial = 'NB'; 
			}
			when 'newfoundland and labrador'{
				stateInitial = 'NL'; 
			}
			when 'prince edward island'{
				stateInitial = 'PE'; 
			}
			when 'northwest territories'{
				stateInitial = 'NT'; 
			}
			when 'yukon'{
				stateInitial = 'YT'; 
			}
			when 'nunavut'{
				stateInitial = 'NU'; 
			}
			when 'district of columbia'{
				stateInitial = 'DC'; 
			}
			when else {
				stateInitial = state;
			}
		}

		return stateInitial;
	}

	public static String getCarrierCorde(String carrierName){
		for(Carrier_SCAC_code__mdt currentCarruerCodeSetting : [SELECT CarrierName__c, Carrier_SCAC_Code__c FROM Carrier_SCAC_code__mdt]){
			if(carrierName == currentCarruerCodeSetting.CarrierName__c){
				return currentCarruerCodeSetting.Carrier_SCAC_Code__c;
			}
		}
		return carrierName;
	}
}