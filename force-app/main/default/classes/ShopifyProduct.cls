global class ShopifyProduct {
    
    	public Long id {get; set;}
        public String title {get; set;}
        public String body_html {get; set;}
        public String vendor {get; set;}
        public String product_type {get; set;}
        /*public Datetime created_at {get; set;}
        public String handle {get; set;}
        public Datetime updated_at {get; set;}
        public Datetime published_at {get; set;}
        public String template_suffix {get; set;}
        public String published_scope {get; set;}*/
        public String tags {get; set;}
        public String admin_graphql_api_id {get; set;}
        public List<Variant> variants {get; set;}
        public List<Option> options {get; set;}
        public List<Image> images {get; set;}
        public Image image {get; set;}
        
        public String getImage(){
            if(image != null && image.src!=null && String.IsNotBlank(image.src))
                return '<img src="' + image.src + '"></img>';
            return '';
    	}
    
        public String getTags(){
        	if(tags!=null)
                return tags.replaceAll(',', ';');
            return tags;
        }
        
        public Decimal getWeight(){
            if(variants != null && variants.size()>0){
                return variants[0].weight;
            }
            return 0.0;
        }
        
        public String getWeightUnit(){
            if(variants != null && variants.size()>0){
                return variants[0].weight_unit;
            }
            return '';
        }
        
        public Integer getInventoryQuantity(){
            if(variants != null && variants.size()>0){
                return variants[0].inventory_quantity;
            }
            return 0;
        }
        
        public Decimal getPrice(){
            if(variants != null && variants.size()>0 && variants[0].price!=null){
                try{
                	return Decimal.valueOf(variants[0].price);
                }catch(Exception e){ System.debug('Exception: Product getPrice -> ' + e.getMessage()); }
            }
            return 0;
        }
        
        public Decimal getComparePrice(){
            if(variants != null && variants.size()>0 && variants[0].compare_at_price!=null){
                try{
                	return Decimal.valueOf(variants[0].compare_at_price);
                }catch(Exception e){ System.debug('Exception: Product getComparePrice -> ' + e.getMessage()); }
            }
            return 0;
        }
        
        public String getSku(){
            if(variants != null && variants.size()>0){
                return variants[0].sku;
            }
            return '';
        }
        
        public Boolean getTaxable(){
            if(variants != null && variants.size()>0){
                return variants[0].taxable;
            }
            return false;
        }
    
    	class Variant{
            /*public Long id {get; set;}
            public Long product_id {get; set;}
            public String title {get; set;}
            public Integer position {get; set;}
            public String inventory_policy {get; set;}*/
            public String price {get; set;}
            public String sku {get; set;}
            public String compare_at_price {get; set;}
            /*public String fulfillment_service {get; set;}
            public String inventory_management {get; set;}
            public String option1 {get; set;}
            public String option2 {get; set;}
            public String option3 {get; set;}
            public Datetime created_at {get; set;}*/
            public Boolean taxable {get; set;}
            /*public String barcode {get; set;}
            public Integer grams {get; set;}
            public Long image_id {get; set;}*/
            public Decimal weight {get; set;}
            public String weight_unit {get; set;}
            public Long inventory_item_id {get; set;}
            public Integer inventory_quantity {get; set;}
            /*public Integer old_inventory_quantity {get; set;}
            public Boolean requires_shipping {get; set;}
            public String admin_graphql_api_id {get; set;}*/
        }
        
        class Option{
            /*public Long id {get; set;}
            public Long product_id {get; set;}
            public String name {get; set;}
            public Integer position {get; set;}
            public List<String> values {get; set;}*/
        }
    
    	class Image{
            /*public Long id {get; set;}
            public Long product_id {get; set;}
            public Integer position {get; set;}
            public Datetime created_at {get; set;}
            public Datetime updated_at {get; set;}
            public String alt {get; set;}
            public Integer width {get; set;}
            public Integer height {get; set;}*/
            public String src {get; set;}
            /*public List<Long> variant_ids {get; set;}
            public String admin_graphql_api_id {get; set;}*/
        }  

}