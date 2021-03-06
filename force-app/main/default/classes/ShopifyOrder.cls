global class ShopifyOrder {

    public Long id {get; set;}
    public String email {get; set;}
    public String token {get; set;}
    public String cancel_reason {get; set;}
    public String created_at {get; set;}
    public String cancelled_at {get; set;}
    public String closed_at {get; set;}
    public String financial_status {get; set;}
    public String fulfillment_status {get; set;}
    public String landing_site {get; set;}
    public Long order_number {get; set;}
    public String note {get; set;}
    public String source_name {get; set;}
    public String subtotal_price {get; set;}
    public Boolean taxes_included {get; set;}
    public String total_discounts {get; set;}
    public String total_price {get; set;}
    public String total_tax {get; set;}
    public List<Discount_Code> discount_codes {get; set;}
    public Billing_Address billing_address {get; set;}
    public Shipping_Address shipping_address {get; set;}
    public Customer customer {get; set;}
    public List<Line_Item> line_items {get; set;}
    public List<Fulfillment> fulfillments {get; set;}

    public String getLandingSite(){
        return landing_site!=null ? landing_site.left(255) : null;
    }
    
    public Datetime getCancelledAt(){
        if(cancelled_at!=null && cancelled_at!='')
        {
            try{
                return Datetime.valueOfGmt(cancelled_at.replace('T', ' '));
            }catch(Exception e){
                System.debug('Exception convert cancelled_at: ' +  e.getMessage());
            }
        }
            
        return null;
    }
    
    public Date getCloseDate(){
        if(closed_at!=null && closed_at!='')
        {
            try{
                return Datetime.valueOfGmt(closed_at.replace('T', ' ')).date();
            }catch(Exception e){
                System.debug('Exception convert closed_at: ' +  e.getMessage());
            }
        }else if(created_at!=null && created_at!=''){
            try{
                return Datetime.valueOfGmt(created_at.replace('T', ' ')).date();
            }catch(Exception e){
                System.debug('Exception convert created_at: ' +  e.getMessage());
            }
        }
            
        return System.now().date();
    }
    
    public Decimal getSubTotal(){
            if(subtotal_price!=null && subtotal_price!=''){
                try{
                	return Decimal.valueOf(subtotal_price);
                }catch(Exception e){
                    System.debug('Exception: Order getSubTotal -> ' + e.getMessage());
                }
            }
            return 0;
    }
    
    public Decimal getTotalDiscounts(){
            if(total_discounts!=null && total_discounts!=''){
                try{
                	return Decimal.valueOf(total_discounts);
                }catch(Exception e){
                    System.debug('Exception: Order getTotalDiscounts -> ' + e.getMessage());
                }
            }
            return 0;
    }
    
    public Decimal getTotalPrice(){
            if(total_price!=null && total_price!=''){
                try{
                	return Decimal.valueOf(total_price);
                }catch(Exception e){
                    System.debug('Exception: Order getTotalPrice -> ' + e.getMessage());
                }
            }
            return 0;
    }
    
    public Decimal getTotalTax(){
            if(total_tax!=null && total_tax!=''){
                try{
                	return Decimal.valueOf(total_tax);
                }catch(Exception e){
                    System.debug('Exception: Order getTotalTax -> ' + e.getMessage());
                }
            }
            return 0;
    }
    
    public Long getCustomerId(){
        if(customer!=null)
            return customer.id;
        return null;
    }
    
    public String getDiscount_Codes(){
        if(discount_codes!=null){
            String auxCodes = '';
            for(Discount_Code dc : discount_codes){
                auxCodes = auxCodes + (dc.code != null && String.isNotBlank(dc.code) ? ', ' + dc.code : '');
            }
            return auxCodes;
        }
        return '';
    }
    
    class Discount_Code{
        public String code {get; set;}
    }
    
    class Billing_Address{
        //public String first_name {get; set;}
        public String address1 {get; set;}
        //public String phone {get; set;}
        public String city {get; set;}
        public String zip {get; set;}
        public String province {get; set;}
        public String country {get; set;}
        //public String last_name {get; set;}
        public String address2 {get; set;}
    }
    
    public String getBillingAddress(){
        if(billing_address!=null)
            return billing_address.address1 + ' ' + billing_address.address2 + ', ' + billing_address.city + ', ' + billing_address.province + ' ' + billing_address.zip;
        return '';
    }
    
    class Shipping_Address{
        //public String first_name {get; set;}
        public String address1 {get; set;}
        //public String phone {get; set;}
        public String city {get; set;}
        public String zip {get; set;}
        public String province {get; set;}
        public String country {get; set;}
        //public String last_name {get; set;}
        public String address2 {get; set;}
    }
    
    public String getShippingAddress(){
        if(shipping_address!=null)
            return shipping_address.address1 + ' ' + shipping_address.address2 + ', ' + shipping_address.city + ', ' + shipping_address.province + ' ' + shipping_address.zip;
        return '';
    }
    
    public String getShippingStreet(){
        if(shipping_address!=null)
            return shipping_address.address1 + ' ' + shipping_address.address2;
        return '';
    }
    
    public String getShippingCity(){
        if(shipping_address!=null)
            return shipping_address.city;
        return '';
    }
    
    public String getShippingState(){
        if(shipping_address!=null)
            return shipping_address.province;
        return '';
    }
    
    public String getShippingZip(){
        if(shipping_address!=null)
            return shipping_address.zip;
        return '';
    }
    
    public String getTrackingNumber(){
        if(fulfillments!=null && fulfillments.size()>0){
            return fulfillments[fulfillments.size()-1].tracking_number;
        }
        return '';
    }
    
    public String getTrackingUrl(){
        if(fulfillments!=null && fulfillments.size()>0){
            return fulfillments[fulfillments.size()-1].tracking_url;
        }
        return '';
    }
    
    public class Customer{
        public Long id {get; set;}
        public String email {get; set;}
        public String first_name {get; set;}
        public String last_name {get; set;}
        public Long last_order_id {get; set;}
    }
    
    public class Line_Item{
        public Long id {get; set;}
        public Long variant_id {get; set;}
        public String title {get; set;}
        public Integer quantity {get; set;}
        public String sku {get; set;}
        public String variant_title {get; set;}
        public Long product_id {get; set;}
        public Boolean requires_shipping {get; set;}
        public Integer fulfillable_quantity {get; set;}
        public String fulfillment_status {get; set;}
        public List<Tax_Line> tax_lines {get; set;}
        public Boolean taxable {get; set;}
        public String total_discount {get; set;}
        public String price {get; set;}
    
        public Decimal getTotalTax(){
            Decimal sumTax = 0.0;
            for(Tax_Line tl : tax_lines){
                sumTax += tl.getPrice();
            } 
            return sumTax;
        }
        
        public Decimal getTotalDiscount(){
            if(total_discount!=null && total_discount!=''){
                try{
                	return Decimal.valueOf(total_discount);
                }catch(Exception e){
                    System.debug('Exception: Order getTotalDiscount Line_Item -> ' + e.getMessage());
                }
            }
            return 0;
    	}
        
        public Decimal getUnitPrice(){
            if(price!=null && price!=''){
                try{
                	return Decimal.valueOf(price);
                }catch(Exception e){
                    System.debug('Exception: Order getUnitPrice Line_Item -> ' + e.getMessage());
                }
            }
            return 0;
    	}
    
    }
    
    public class Tax_Line{
        public String title {get; set;}
        public String price {get; set;}
        
        public Decimal getPrice(){
            if(price!=null && price!=''){
                try{
                	return Decimal.valueOf(price);
                }catch(Exception e){
                    System.debug('Exception: Order getPRice Tax Line -> ' + e.getMessage());
                }
            }
            return 0;
    	}
    }
    
    class Fulfillment{
        public Long id {get; set;}
        public String tracking_number {get; set;}
        public String tracking_url {get; set;}
    }
}