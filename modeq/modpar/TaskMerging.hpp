#ifndef _TASKMERGING_HPP
#define _TASKMERGING_HPP

#include "TaskGraph.hpp"
#include "ParallelOptions.hpp"
#include "MergeRule.hpp"


using namespace std;

class TaskMerging 
{
public:
  // Methods
  TaskMerging();
  ~TaskMerging();
  void merge(TaskGraph *,TaskGraph *,ParallelOptions *,VertexID, VertexID, ContainSetMap*);

  VertexID get_starttask() {return m_invartask;};
  VertexID get_endtask() { return m_outvartask;};

private:
  void initializeRules();
  void mergeRules();
  void updateExecCosts();

  void addContainsTask(VertexID, VertexID);

  // Helper functions for singleChildMerge
  void mergeTasks(VertexID n1, VertexID n2);
  
  std::pair<VertexID,VertexID> determineParent(VertexID n1, VertexID n2);  
  
  // Helper functions for duplicateParentMerge
  vector<bool> * newTlevelLower(pair<ChildrenIterator ,ChildrenIterator> pair,
				VertexID parent,
				TaskGraph *tg);

  vector<bool> *siblingCondition(pair<ChildrenIterator,ChildrenIterator> pair,
				 VertexID parent,
				 TaskGraph *tg);

  bool allSiblingsCondition(std::pair<ParentsIterator,ParentsIterator> pair,
			    VertexID child,
			    VertexID parent,
			    TaskGraph *tg);

  int numberOfTrues(vector<bool> *v);
  
  void printTaskInfo();
  // Variables
  double m_latency;
  double m_bandwidth;
  bool m_change; // True when task graph changed because of rewrite rule.
  TaskGraph *m_taskgraph; 
  TaskGraph *m_orig_taskgraph;
  ContainSetMap *m_containTasks;
  VertexID m_invartask;
  VertexID m_outvartask;

  MergeRule **m_rules;
  const int m_num_rules;
  
};





#endif
