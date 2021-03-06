class AppsController < ApplicationController

  before_filter :login_required
  before_filter :find_app
  
  def getcred
    @sub=Membership.find params[:sub_id]
    if @sub and @sub.credential.nil?
      @sub.credential=Credential.new
      @sub.credential.save
      @sub.save
    end
  end
  
  def givecred
    @sub=Membership.find params[:sub_id]
    @sub.credential.login=params[:login]
    @sub.credential.password=params[:password]
    @sub.credential.token=params[:token]
    @sub.credential.url=params[:url]
    @sub.credential.save
    @sub.save
    flash[:notice]="Updated credential for membership"
    redirect_to :action=>'edit'
  end

  # GET /apps
  # GET /apps.xml
  def index
    if @current_user
      login=@current_user.login
      admins = @current_user.administrations
      @apps=admins.map {|a| a.app}
      @clients=@current_user.clients
    else
      login="anonymous"
      @current_user=User.find 1
    end

    if @apps.nil?
      flash[:notice]="You have no existing apps"
    end
    @allapps=App.find :all
    @subapps=@allapps.reject { |app| app.anonymous!=1 and !@current_user.apps.index(app) }
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @apps }
    end
  end

  # GET /apps/1
  # GET /apps/1.xml
  def show
    @isadmin=Administration.find_by_user_id_and_app_id @current_user.id,@app.id  # is the current user an admin?  
    @sub=Membership.find_by_app_id_and_user_id @app.id,@current_user.id
    @sources=@app.sources
    @users=User.find :all
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @app }
    end
  end
  
  def refresh # execute a refresh on all sources associated with an app 
    @sources=Source.find_all_by_app_id @app.id,:order=>:priority
    @sources.each do |src|
      src.refresh(@current_user, session)
    end
    flash[:notice]="Refreshed all sources"
    redirect_to :action=>:edit
  end

  # GET /apps/new
  # GET /apps/new.xml
  def new
    @app = App.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @app }
    end
  end

  # GET /apps/1/edit
  def edit
    @users = User.find :all
    @users.delete_if {|user| user.name=="anonymous"}
    @admins= Administration.find_all_by_app_id @app.id
    @isadmin=Administration.find_by_user_id_and_app_id @current_user.id,@app.id  # is the current user an admin?
    if !@isadmin 
      redirect_to :action=>"show"
    end
  end
  
  def add_user_to_app(login,app)
    user=User.find_by_login login
    app.users << user  if user
    app.save
    if (params[:url]) # we have a URL of a credential
      @sub=Membership.find_by_user_id_and_app_id user.id,app.id  # find the just created membership subscription
      @sub.credential=Credential.new
      @sub.credential.url=params[:url]
      @sub.credential.login=params[:login]
      @sub.credential.password=params[:password]
      @sub.credential.token=params[:token]
      @sub.credential.save
      @sub.save
    end
  end
  
  # subscribe specified subscriber to specified app ID
  def subscribe
    @app=App.find_by_permalink(params[:app_id]) 
    @app||=App.find(params[:id]) 
    if @app.stop_subscriptions==true
      logger.info "This application has disallowed subscriptions"
      return
    end
    user=@current_user
    if params[:subscriber]
      @current_user=User.find_by_login params[:subscriber] 
      user=@current_user
    else
      if @current_user.nil? or @current_user.login=="anonymous" # create the new user on the fly
        redirect_to :controller=>"sessions/create",:login=>params[:login],:password=>params[:password],:email=>params[:email],:app_id=>params[:app_id]
        return
      end
    end
    add_user_to_app(user.login,@app)
    redirect_to :action=>:edit,:id=>@app.id
  end

  # unsubscribe subscriber to specified app ID 
  def unsubscribe
    @app=App.find_by_permalink(params[:app_id]) 
    @app||=App.find(params[:id])     
    user=@current_user
    if params[:subscriber]
      @current_user=User.find_by_login params[:subscriber] 
      user=@current_user
    else
      if @current_user.nil? or @current_user.login=="anonymous" # create the new user on the fly
        redirect_to :controller=>"sessions/create",:login=>params[:login],:password=>params[:password],:email=>params[:email],:app_id=>params[:app_id]
        return
      end
    end 
    @app.users.delete user
    redirect_to :action=>:edit,:id=>@app.id
  end
  
  # add specified user as administrator
  def administer
    user=User.find_by_login params[:administrator]
    @app=App.find_by_permalink(params[:id])
    admin=Administration.new
    admin.user=user
    admin.save
    @app.administrations << admin
    redirect_to :action=>:edit
  end
  
  def unadminister
    admin=User.find_by_login params[:administrator]
    @app=App.find_by_permalink params[:id]
    administration=Administration.find_by_user_id_and_app_id admin.id,@app.id  
    administration.delete
    redirect_to :action=>:edit
  end
  
  # POST /apps
  # POST /apps.xml
  def create
    error=nil
    @app = App.new(params[:app])
    if App.find_by_name @app.name
      error="App already exists. Please try a different name."
    else 
      @app.save
      admin=Administration.new
      admin.user_id=@current_user.id
      admin.app_id=@app.id
      admin.save
    end
    respond_to do |format|
      if not error and @app.save
        flash[:notice] = 'App was successfully created.'
        format.html { redirect_to(apps_url) }
        format.xml  { render :xml => @app, :status => :created, :location => @app }
      else
        flash[:notice]=error
        format.html { render :action => "new" }
        format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/1
  # PUT /apps/1.xml
  def update
    respond_to do |format|
      if @app.update_attributes(params[:app])
        flash[:notice] = 'App was successfully updated.'
        format.html { redirect_to(apps_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /apps/1
  # DELETE /apps/1.xml
  def destroy
    @app.destroy

    respond_to do |format|
      format.html { redirect_to(apps_url) }
      format.xml  { head :ok }
    end
  end
  
  protected
  
  def find_app
    @app = App.find_by_permalink(params[:id]) if params[:id]
  end
end
