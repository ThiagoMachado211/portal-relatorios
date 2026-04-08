class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.order(:name, :email)
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_users_path, notice: "Usuário criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    filtered_params = user_params

    if filtered_params[:password].blank?
      filtered_params = filtered_params.except(:password, :password_confirmation)
    end

    if @user.update(filtered_params)
      redirect_to admin_users_path, notice: "Usuário atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "Você não pode excluir seu próprio usuário."
      return
    end

    @user.destroy
    redirect_to admin_users_path, notice: "Usuário removido com sucesso."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :user_type,
      :password,
      :password_confirmation
    )
  end
end