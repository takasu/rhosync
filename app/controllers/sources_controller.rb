require 'soap/wsdlDriver'
require 'digest/md5'

class SourcesController < ApplicationController

  # helper function to come up with the string used for the name_value_list
  # name_value_list =  [ { "name" => "name", "value" => "rhomobile" },
  #                     { "name" => "industry", "value" => "software" } ]
  def make_name_value_list(hash)
    result="["
    hash.keys.each do |x|
      result << ('{ "name" => "'+ x +'", "value" => ' + h[x] + '},')
    end
    result=result[0...size-1] # chop off the last comma!
    result += "]"
  end

  # this connect to the web service of the given source backend and:
  # - does a prolog (generally logging in)
  # - does updating of records as required
  # - reads records from the backend
  # - does an epilog (logs off)
  def refresh

    @source=Source.find params[:id]
    client = SOAP::WSDLDriverFactory.new(@source.url).create_rpc_driver
    # make sure to use client and session_id variables
    # in your code that is edited into each source!
    callbinding=eval(@source.prolog+";binding")

    # first do all the the creates
    if @source.createcall and @source.createcall.size>0
      createobjects=ObjectValue.find_by_sql("select distinct(object) from object_values where object_type='create'")
      createobjects.each do |x|
        xvals=ObjectValue.find_by_object(x)  # this has all the attribute value pairs for this particular object
        attrvalues={}
        xvals.each do |y|
          attrvalues[y.attribute]=y.value
          y.destroy
        end
        # now attrvalues has the attribute values needed for the createcall
        # the Sugar adapter will use the name_value_list variable that we're building up here
        # TODO: name_value_list is probably too specific to Sugar
        # TODO: need a clean way to pass the attrvalues hash to any adapter cleanly
        nvlist=make_name_value_list(attrvalues)
        callbinding=eval("name_value_list="+nvlist+";"+@source.createcall+";binding",callbinding)
      end
    end

    # now do the updates
    if @source.updatecall and @source.updatecall.size>0
      updateobjects=ObjectValue.find_by_sql("select distinct(object) from object_values where object_type='update'")
      updateobjects.each do |x|
        objvals=ObjectValue.find_by_object(x)  # this has all the attribute value pairs now
        attrvalues={}
        attrvalues["id"]=x.object  # setting the ID allows it be an update
        objvals.each do |y|
          attrvalues[y.attribute]=y.value
          y.destroy
        end
        # now attrvalues has the attribute values needed for the createcall
        nvlist=make_name_value_list(attrvalues)
        callbinding=eval("name_value_list="+nvlist+";"+@source.updatecall+";binding",callbinding)
      end
    end

    # now do the deletes
    if @source.updatecall and @source.updatecall.size>0
      objvals=ObjectValue.find_by_sql("select distinct(object) from object_values where object_type='delete'")
      deleteobjects.each do |x|
        attrvalues={}
        attrvalues["id"]=x.object
        nvlist=make_name_value_list(attrvalues)
        callbinding=eval("namevaluelist="+nvlist+";"+@source.deletecall+";binding",callbinding)
        x.destroy
      end
    end

    if @source.call
      # now do the query call
      callbinding=eval(@source.call+";binding",callbinding)
      # now take apart the returned data 
      callbinding=eval(@source.sync,callbinding)
    end
    
    # now do the logoff
    callbinding=eval(@source.epilog+ ";binding",callbinding) if @source.epilog
    eval(@source.sync,callbinding)
    redirect_to :controller=>"sources",:action=>"show"
  end


  # GET /sources
  # GET /sources.xml
  def index
    @sources = Source.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sources }
    end
  end

  # GET /sources/1
  # GET /sources/1.xml
  def show
    @source = Source.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @source }
    end
  end

  # GET /sources/new
  # GET /sources/new.xml
  def new
    @source = Source.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @source }
    end
  end

  # GET /sources/1/edit
  def edit
    @source = Source.find(params[:id])
    render :action=>"edit"
  end

  # POST /sources
  # POST /sources.xml
  def create
    @source = Source.new(params[:source])

    respond_to do |format|
      if @source.save
        flash[:notice] = 'Source was successfully created.'
        format.html { redirect_to(@source) }
        format.xml  { render :xml => @source, :status => :created, :location => @source }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sources/1
  # PUT /sources/1.xml
  def update
    @source = Source.find(params[:id])

    respond_to do |format|
      if @source.update_attributes(params[:source])
        flash[:notice] = 'Source was successfully updated.'
        format.html { redirect_to(@source) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sources/1
  # DELETE /sources/1.xml
  def destroy
    @source = Source.find(params[:id])
    @source.destroy

    respond_to do |format|
      format.html { redirect_to(sources_url) }
      format.xml  { head :ok }
    end
  end
end
