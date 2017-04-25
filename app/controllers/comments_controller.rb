class CommentsController < ApplicationController
  before_action :set_comment, only: [:edit, :update, :destroy]
  before_action :load_commentable, only: [:create]

  def create
    @comment = Comment.new(comment_params.merge(commentable: @commentable, user: current_user))
    authorize @comment
    if @comment.save
      redirect_to [@commentable, comment: @comment.comment_type], notice: "Opmerking is toegevoegd."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @comment.update_attributes(comment_params)
      redirect_to [@comment.commentable, comment: @comment.comment_type], notice: "Opmerking is aangepast."
    else
      render 'edit'
    end
  end

  def destroy
    redirect_to [@comment.commentable, comment: @comment.comment_type], notice: "Opmerking is verwijderd."
    @comment.destroy
  end

  private
    def set_comment
      @comment = Comment.find(params[:id])
      authorize @comment
    end

    def load_commentable
      resource, id = request.path.split('/')[1, 2]
      @commentable = resource.singularize.classify.constantize.find(id)
    end

    def comment_params
      params.require(:comment).permit(:body, :comment_type, :private)
    end
end
